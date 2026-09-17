import SwiftUI

/// "Reminders & Preferences": smart hydration alerts (presets + custom
/// interval, 24-hour active window), sounds & haptics (device sound library +
/// volume), targets (goal +/- editor), container presets editor, Apple Health,
/// and data controls.
struct SettingsView: View {
    @EnvironmentObject var store: HydrationStore
    @EnvironmentObject var notificationScheduler: NotificationScheduler
    @EnvironmentObject var soundManager: SoundManager
    @EnvironmentObject var healthKit: HealthKitManager

    @State private var showGoalEditor = false
    @State private var showIntervalPicker = false
    @State private var showActiveHoursPicker = false
    @State private var showProfileEditor = false
    @State private var showSoundPicker = false
    @State private var showPresetsEditor = false
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                statusBanner
                remindersSection
                soundsSection
                targetsSection
                aboutFooter
            }
            .padding(.horizontal, .margin)
            .padding(.top, 8)
            .padding(.bottom, 110)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .background(Theme.canvas)
        .navigationTitle("Reminders & Preferences")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showGoalEditor) { goalEditor }
        .sheet(isPresented: $showIntervalPicker) { intervalPicker }
        .sheet(isPresented: $showActiveHoursPicker) { activeHoursPicker }
        .sheet(isPresented: $showProfileEditor) { profileEditor }
        .sheet(isPresented: $showSoundPicker) { soundPicker }
        .sheet(isPresented: $showPresetsEditor) { presetsEditor }
        .alert("Reset all hydration history?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                store.resetHistory()
            }
        } message: {
            Text("Logged entries will be permanently removed. Your profile and settings are kept.")
        }
    }

    // MARK: - Status banner

    private var statusBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.azure)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("Next Drink Alert")
                    .font(FlowFont.bodyBold())
                Text(nextAlertText)
                    .font(FlowFont.caption())
                    .foregroundStyle(Theme.labelSecondary)
            }
            Spacer()
            Text(bannerBadge)
                .font(FlowFont.caption())
                .fontWeight(.bold)
                .foregroundStyle(Theme.brandPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Theme.card))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Theme.azure.opacity(0.14), Theme.aqua.opacity(0.12)],
                                     startPoint: .leading, endPoint: .trailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.azure.opacity(0.18), lineWidth: 0.5)
        )
    }

    private var nextAlertText: String {
        let times = NotificationScheduler.plannedReminderTimes(settings: store.reminderSettings)
        guard !times.isEmpty else { return "Reminders paused" }
        // Next slot at/after the current time, else the first one tomorrow.
        let hour = Calendar.current.component(.hour, from: Date())
        let next = times.first { $0.hour >= hour } ?? times[0]
        let label = next.hour >= 12 ? "PM" : "AM"
        let displayHour = next.hour % 12 == 0 ? 12 : next.hour % 12
        let day = (next.hour < hour) ? "tomorrow" : "today"
        return "\(day) at \(displayHour):\(String(format: "%02d", next.minute)) \(label)"
    }

    private var bannerBadge: String {
        store.reminderSettings.remindersEnabled && !store.reminderSettings.bedtimeMode
            ? "On Schedule"
            : "Paused"
    }

    // MARK: - Reminders

    private var remindersSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Smart Hydration Alerts")
            VStack(spacing: 0) {
                ToggleRow(
                    icon: "bell.fill", iconTint: Theme.azure,
                    title: "Drink Reminders",
                    subtitle: "Scheduled nudges during daytime",
                    isOn: $store.reminderSettings.remindersEnabled
                )
                .onChange(of: store.reminderSettings.remindersEnabled) { _, _ in rescheduleNotifications() }
                Divider().padding(.leading, 54)

                row(icon: "timer", iconTint: Theme.aqua, title: "Reminder Interval") {
                    Text(store.reminderSettings.intervalDisplayText)
                        .font(FlowFont.subhead())
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.brandPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.labelTertiary)
                }
                .contentShape(Rectangle())
                .onTapGesture { showIntervalPicker = true }
                Divider().padding(.leading, 54)

                row(icon: "clock", iconTint: Theme.indigo, title: "Active Hours") {
                    Text(activeHoursText)
                        .font(FlowFont.subhead())
                        .foregroundStyle(Theme.labelSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.labelTertiary)
                }
                .contentShape(Rectangle())
                .onTapGesture { showActiveHoursPicker = true }
                Divider().padding(.leading, 54)

                ToggleRow(
                    icon: "moon.zzz.fill", iconTint: Theme.indigo,
                    title: "Bedtime Mode",
                    subtitle: "Mutes all hydration alerts while asleep",
                    isOn: $store.reminderSettings.bedtimeMode
                )
                .onChange(of: store.reminderSettings.bedtimeMode) { _, _ in rescheduleNotifications() }
                Divider().padding(.leading, 54)

                ToggleRow(
                    icon: "sun.max.fill", iconTint: .orange,
                    title: "Dynamic Weather",
                    subtitle: weatherSubtitle,
                    isOn: $store.reminderSettings.dynamicWeather
                )
                .onChange(of: store.reminderSettings.dynamicWeather) { _, _ in store.refreshWeatherBonus() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .flowCardBackground()
        }
    }

    // MARK: - Sounds

    private var soundsSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Sounds & Haptics")
            VStack(spacing: 0) {
                row(icon: "speaker.wave.2.fill", iconTint: Theme.aqua, title: "Notification Sound") {
                    Text(soundDisplayText)
                        .font(FlowFont.subhead())
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.brandPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.labelTertiary)
                }
                .contentShape(Rectangle())
                .onTapGesture { showSoundPicker = true }
                Divider().padding(.leading, 54)

                ToggleRow(
                    icon: "iphone.radiowaves.left.and.right", iconTint: Theme.indigo,
                    title: "Haptic Feedback",
                    subtitle: "Subtle water droplet resonance",
                    isOn: $store.reminderSettings.hapticsEnabled
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .flowCardBackground()
        }
    }

    private var soundDisplayText: String {
        if let option = soundManager.option(forID: store.reminderSettings.soundName) {
            return option.displayName
        }
        return "System Default"
    }

    // MARK: - Targets

    private var targetsSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Targets & Integration")
            VStack(spacing: 0) {
                row(icon: "flag.fill", iconTint: Theme.azure, title: "Daily Goal",
                    subtitle: "Tap to raise, lower, or recalculate") {
                    Text("\(Int(store.profile.unit.value(fromML: store.baseGoalML).rounded())) \(store.profile.unit.symbol)")
                        .font(FlowFont.headlineSmall())
                        .foregroundStyle(Theme.brandPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.labelTertiary)
                }
                .contentShape(Rectangle())
                .onTapGesture { showGoalEditor = true }
                Divider().padding(.leading, 54)

                row(icon: "heart.fill", iconTint: Theme.destructive, title: "Apple Health Sync",
                    subtitle: "Writes every logged drink to HealthKit") {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(healthStatusColor)
                            .frame(width: 8, height: 8)
                        Text(healthStatusText)
                            .font(FlowFont.subhead())
                            .fontWeight(.semibold)
                            .foregroundStyle(healthStatusColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { Task { await connectHealth() } }
                Divider().padding(.leading, 54)

                row(icon: "cup.and.saucer.fill", iconTint: Theme.indigo, title: "Container Presets",
                    subtitle: "\(store.containerPresets.count) vessels · tap to edit") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.labelTertiary)
                }
                .contentShape(Rectangle())
                .onTapGesture { showPresetsEditor = true }
                Divider().padding(.leading, 54)

                row(icon: "figure.arms.open", iconTint: .orange, title: "Profile & Units",
                    subtitle: "Weight, activity, climate, ml/oz") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.labelTertiary)
                }
                .contentShape(Rectangle())
                .onTapGesture { showProfileEditor = true }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .flowCardBackground()
        }
    }

    private var healthStatusText: String {
        if !healthKit.isAvailable { return "Unavailable" }
        return healthKit.isAuthorized ? "Connected" : "Tap to connect"
    }

    private var healthStatusColor: Color {
        if !healthKit.isAvailable { return Theme.labelTertiary }
        return healthKit.isAuthorized ? Theme.success : .orange
    }

    private var aboutFooter: some View {
        VStack(spacing: 10) {
            Button(role: .destructive) {
                confirmReset = true
            } label: {
                Text("Reset Hydration History")
                    .font(FlowFont.bodyBold())
                    .foregroundStyle(Theme.destructive)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.destructive.opacity(0.10)))
            }
            .buttonStyle(.plain)

            VStack(spacing: 3) {
                Text("HydroFlow v1.1 (Build 2)")
                Text("Designed with Apple HealthKit Integration")
            }
            .font(FlowFont.caption())
            .foregroundStyle(Theme.labelTertiary)
        }
    }

    // MARK: - Generic row

    @ViewBuilder
    private func row<Trailing: View>(icon: String, iconTint: Color, title: String,
                                     subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            IconTile(systemName: icon, tint: iconTint, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FlowFont.bodyBold())
                    .foregroundStyle(Theme.labelPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(FlowFont.caption())
                        .foregroundStyle(Theme.labelSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
            }
            Spacer()
            trailing()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Interval picker (presets + custom)

    private var intervalPicker: some View {
        NavigationStack {
            List {
                Section("Recommended") {
                    ForEach(ReminderInterval.allCases) { interval in
                        intervalRow(title: interval.displayName,
                                    subtitle: cadenceHint(for: interval),
                                    isSelected: store.reminderSettings.customIntervalMinutes == nil &&
                                                store.reminderSettings.interval == interval) {
                            store.reminderSettings.customIntervalMinutes = nil
                            store.reminderSettings.interval = interval
                            rescheduleNotifications()
                        }
                    }
                }
                Section("Custom") {
                    customIntervalRow
                }
            }
            .navigationTitle("Reminder Interval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showIntervalPicker = false }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func cadenceHint(for interval: ReminderInterval) -> String {
        switch interval {
        case .thirtyMinutes: "Very frequent — great for building the habit"
        case .fortyFiveMinutes: "Frequent — ~10 sips per 8-hour day"
        case .oneHour: "Steady rhythm — the classic choice"
        case .ninetyMinutes: "Balanced — the recommended default"
        case .twoHours: "Relaxed — about 7 reminders per day"
        case .twoHalfHours: "Light — for those who drink big volumes"
        case .threeHours: "Minimal — just the essentials"
        }
    }

    @State private var customIntervalMinutes: Double = 75
    @State private var useCustomInterval = false

    private var customIntervalRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Custom interval", isOn: $useCustomInterval)
                .font(FlowFont.bodyBold())
                .tint(Theme.azure)
                .onChange(of: useCustomInterval) { _, isOn in
                    if isOn {
                        store.reminderSettings.customIntervalMinutes = customIntervalMinutes
                        rescheduleNotifications()
                    } else {
                        store.reminderSettings.customIntervalMinutes = nil
                        rescheduleNotifications()
                    }
                }

            if useCustomInterval {
                HStack {
                    Text("\(Int(customIntervalMinutes.rounded())) min")
                        .font(FlowFont.stat(22))
                        .monospacedDigit()
                        .foregroundStyle(Theme.brandPrimary)
                        .frame(minWidth: 110, alignment: .leading)
                    Slider(value: $customIntervalMinutes, in: 10...240, step: 5) { editing in
                        if !editing {
                            store.reminderSettings.customIntervalMinutes = customIntervalMinutes
                            rescheduleNotifications()
                        }
                    }
                    .tint(Theme.azure)
                }

                Text("Between 10 and 240 minutes. You'll get about \(max(1, Int((minutesInWindow / customIntervalMinutes).rounded()))) reminders per active day.")
                    .font(FlowFont.caption())
                    .foregroundStyle(Theme.labelSecondary)
            }
        }
        .padding(.vertical, 6)
        .onAppear {
            if let custom = store.reminderSettings.customIntervalMinutes {
                useCustomInterval = true
                customIntervalMinutes = custom
            }
        }
    }

    private var minutesInWindow: Double {
        let s = store.reminderSettings
        let window = s.wrapsMidnight
            ? (24 * 60 - Double(s.activeStartHour) * 60) + Double(s.activeEndHour) * 60
            : Double(s.activeEndHour - s.activeStartHour) * 60
        return max(60, window)
    }

    private func intervalRow(title: String, subtitle: String, isSelected: Bool,
                             action: @escaping () -> Void) -> some View {
        Button {
            Feedback.tick(enabled: store.reminderSettings.hapticsEnabled)
            action()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(FlowFont.bodyBold())
                        .foregroundStyle(Theme.labelPrimary)
                    Text(subtitle)
                        .font(FlowFont.caption())
                        .foregroundStyle(Theme.labelSecondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.azure)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Active hours (full 24h, wrap-safe)

    private var activeHoursPicker: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Active Hours")
                    .font(FlowFont.headline())
                    .padding(.top, 20)

                Text("Pick any window across the full 24 hours — including overnight (e.g. 8 PM → 6 AM).")
                    .font(FlowFont.caption())
                    .foregroundStyle(Theme.labelSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    hourPicker(selection: $store.reminderSettings.activeStartHour)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(Theme.labelTertiary)
                    hourPicker(selection: $store.reminderSettings.activeEndHour)
                }

                // Quick presets.
                HStack(spacing: 8) {
                    ForEach([(8, 22, "8 AM – 10 PM"), (7, 23, "7 AM – 11 PM"), (6, 0, "6 AM – 12 AM"), (20, 6, "Night shift")],
                            id: \.2) { start, end, label in
                        Button {
                            store.reminderSettings.activeStartHour = start
                            store.reminderSettings.activeEndHour = end
                            rescheduleNotifications()
                        } label: {
                            Text(label)
                                .font(FlowFont.caption(11))
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.brandPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Theme.azure.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if store.reminderSettings.wrapsMidnight {
                    Label("Window crosses midnight — reminders continue overnight", systemImage: "moon.stars.fill")
                        .font(FlowFont.caption())
                        .foregroundStyle(Theme.indigo)
                }

                saveHoursButton
                Spacer()
            }
            .presentationDetents([.height(420)])
            .background(Theme.card)
            .navigationTitle("Active Hours")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// Wheel picker over all 24 hours (0–23), formatted as 12 AM … 11 PM.
    private func hourPicker(selection: Binding<Int>) -> some View {
        Picker("Hour", selection: selection) {
            ForEach(0..<24, id: \.self) { hour in
                Text(Self.hourLabel(for: hour)).tag(hour)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private static func hourLabel(for hour: Int) -> String {
        let display = hour % 12 == 0 ? 12 : hour % 12
        return "\(display) \(hour < 12 ? "AM" : "PM")"
    }

    private var saveHoursButton: some View {
        Button {
            rescheduleNotifications()
            showActiveHoursPicker = false
        } label: {
            Text("Save")
                .font(FlowFont.headlineSmall())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Capsule().fill(Theme.flowGradient))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    // MARK: - Sound picker

    private var soundPicker: some View {
        NavigationStack {
            Group {
                if soundManager.options.count <= 1 {
                    // Library enumeration unavailable (unexpected) — show fallback.
                    VStack(spacing: 10) {
                        Image(systemName: "speaker.slash")
                            .font(.system(size: 36))
                            .foregroundStyle(Theme.labelTertiary)
                        Text("Device sound library unavailable")
                            .font(FlowFont.bodyBold())
                        Text("Using bundled HydroFlow sounds only.")
                            .font(FlowFont.caption())
                            .foregroundStyle(Theme.labelSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section("Volume") {
                            HStack {
                                Image(systemName: "speaker.fill")
                                    .foregroundStyle(Theme.labelSecondary)
                                Slider(value: $store.reminderSettings.soundVolume, in: 0...1) { editing in
                                    if !editing {
                                        previewSelected()
                                    }
                                }
                                .tint(Theme.azure)
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundStyle(Theme.labelSecondary)
                            }
                        }

                        Section("Sounds (\(soundManager.options.count) available)") {
                            ForEach(soundManager.options) { option in
                                soundRow(option)
                            }
                        }

                        Section {
                            Text("System sounds are previewed from your iPhone's built-in library. The selected sound is used for hydration reminders.")
                                .font(FlowFont.caption())
                                .foregroundStyle(Theme.labelSecondary)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.canvas)
            .navigationTitle("Notification Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        soundManager.stopPreview()
                        showSoundPicker = false
                        rescheduleNotifications()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onDisappear { soundManager.stopPreview() }
        }
        .presentationDetents([.large])
    }

    private func soundRow(_ option: SoundOption) -> some View {
        let isSelected = store.reminderSettings.soundName == option.id
        return Button {
            Feedback.tick(enabled: store.reminderSettings.hapticsEnabled)
            store.reminderSettings.soundName = option.id
            // Make sure the sound will actually work for notifications.
            _ = soundManager.installForNotifications(option)
            preview(option)
        } label: {
            HStack {
                Image(systemName: iconName(for: option))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.azure)
                    .frame(width: 28)

                Text(option.displayName)
                    .font(FlowFont.body())
                    .foregroundStyle(Theme.labelPrimary)

                Spacer()

                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.labelTertiary)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.azure)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func iconName(for option: SoundOption) -> String {
        switch option.source {
        case .systemDefault: "applelogo"
        case .bundled: "drop.fill"
        case .systemLibrary: "waveform"
        }
    }

    private func previewSelected() {
        if let option = soundManager.option(forID: store.reminderSettings.soundName) {
            preview(option)
        }
    }

    private func preview(_ option: SoundOption) {
        soundManager.preview(option, volume: store.reminderSettings.soundVolume)
    }

    // MARK: - Container presets editor

    private var presetsEditor: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($store.containerPresets) { $preset in
                        presetRow($preset)
                    }
                    .onDelete { indexSet in
                        guard store.containerPresets.count > indexSet.count else { return }
                        store.containerPresets.remove(atOffsets: indexSet)
                    }
                    .onMove { from, to in
                        store.containerPresets.move(fromOffsets: from, toOffset: to)
                    }
                } header: {
                    Text("Your vessels — shown on the Today quick-log shelf")
                } footer: {
                    Text("Tap a row to rename it or change its volume. Drag to reorder; swipe to delete (keep at least one).")
                }

                Section {
                    Button {
                        addPreset()
                    } label: {
                        Label("Add Container", systemImage: "plus.circle.fill")
                            .font(FlowFont.bodyBold())
                            .foregroundStyle(Theme.azure)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("Container Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showPresetsEditor = false }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func presetRow(_ binding: Binding<ContainerPreset>) -> some View {
        NavigationLink {
            PresetDetailEditor(preset: binding)
        } label: {
            HStack(spacing: 12) {
                IconTile(systemName: binding.wrappedValue.symbolName, tint: Theme.azure, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(binding.wrappedValue.name.isEmpty ? "Untitled" : binding.wrappedValue.name)
                        .font(FlowFont.bodyBold())
                        .foregroundStyle(Theme.labelPrimary)
                    Text(binding.wrappedValue.volumeText(unit: store.profile.unit))
                        .font(FlowFont.caption())
                        .foregroundStyle(Theme.labelSecondary)
                }
            }
        }
    }

    private func addPreset() {
        Feedback.tick(enabled: store.reminderSettings.hapticsEnabled)
        let new = ContainerPreset(name: "New Container", volumeML: 250, symbolName: "water.glass.fill")
        withAnimation { store.containerPresets.append(new) }
    }

    // MARK: - Sheets & logic

    private var goalEditor: some View {
        GoalEditorSheet()
            .presentationDetents([.medium])
    }

    private var profileEditor: some View {
        ProfileEditorSheet()
    }

    private var activeHoursText: String {
        let s = store.reminderSettings
        return "\(Self.hourLabel(for: s.activeStartHour)) – \(Self.hourLabel(for: s.activeEndHour))"
    }

    private var weatherSubtitle: String {
        WeatherProviding.isHotDay() ? "Hot day detected — bonus active!" : "Auto-adds +12 oz on high heat days"
    }

    private func connectHealth() async {
        _ = await healthKit.requestAuthorization()
    }

    private func rescheduleNotifications() {
        notificationScheduler.reschedule(settings: store.reminderSettings, soundManager: soundManager)
    }
}

// MARK: - Per-preset detail editor

/// Rename a container, change its volume, pick its icon and default beverage.
struct PresetDetailEditor: View {
    @Binding var preset: ContainerPreset
    @EnvironmentObject var store: HydrationStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Name") {
                TextField("Container name", text: $preset.name)
            }

            Section("Volume") {
                HStack {
                    Text("\(Int(store.profile.unit.value(fromML: preset.volumeML).rounded()))")
                        .font(FlowFont.stat(28))
                        .monospacedDigit()
                        .foregroundStyle(Theme.brandPrimary)
                        .frame(minWidth: 64, alignment: .leading)
                    Text(store.profile.unit.symbol)
                        .font(FlowFont.bodyBold())
                        .foregroundStyle(Theme.labelSecondary)
                    Stepper("", onIncrement: { stepPreset(+1) }, onDecrement: { stepPreset(-1) })
                        .labelsHidden()
                }
                Text("\(Int(preset.volumeML.rounded())) ml")
                    .font(FlowFont.caption())
                    .foregroundStyle(Theme.labelSecondary)
            }

            Section("Icon") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    ForEach(ContainerPreset.availableSymbols, id: \.self) { symbol in
                        Button {
                            preset.symbolName = symbol
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(preset.symbolName == symbol ? Theme.azure : Theme.azure.opacity(0.07))
                                Image(systemName: symbol)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(preset.symbolName == symbol ? .white : Theme.azure)
                            }
                            .frame(height: 48)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Default Beverage") {
                Picker("Beverage", selection: $preset.beverage) {
                    ForEach(BeverageType.allCases) { beverage in
                        Text(beverage.displayName).tag(beverage)
                    }
                }
            }
        }
        .navigationTitle("Edit Container")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stepPreset(_ direction: Int) {
        let step = store.profile.unit == .fluidOunces ? VolumeUnit.mlPerOz : 50
        preset.volumeML = min(max(preset.volumeML + Double(direction) * step, 30), 2000)
    }
}

// MARK: - Goal editor

/// Daily-goal editor: raise/lower steppers, slider, reset to profile value.
struct GoalEditorSheet: View {
    @EnvironmentObject var store: HydrationStore
    @Environment(\.dismiss) private var dismiss

    @State private var draftGoalML: Double = 0
    @State private var didLoad = false

    var body: some View {
        let unit = store.profile.unit
        let profileGoal = GoalCalculator.dailyGoalML(profile: store.profile)

        return VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Daily Goal")
                    .font(FlowFont.headline())
                Text("Profile recommendation: \(Int(unit.value(fromML: profileGoal).rounded())) \(unit.symbol)")
                    .font(FlowFont.subhead())
                    .foregroundStyle(Theme.labelSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            // Big value with −/+ flanks.
            HStack(spacing: 22) {
                Button {
                    changeDraft(-unitStep)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.azure)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Theme.azure.opacity(0.10)))
                }
                .buttonStyle(.plain)

                VStack(spacing: 2) {
                    Text("\(Int(unit.value(fromML: draftGoalML).rounded()))")
                        .font(FlowFont.stat(40))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(unit.symbol)
                        .font(FlowFont.bodyBold())
                        .foregroundStyle(Theme.labelSecondary)
                    Text("\(Int(draftGoalML.rounded())) ml")
                        .font(FlowFont.caption())
                        .foregroundStyle(Theme.labelTertiary)
                }
                .frame(minWidth: 120)

                Button {
                    changeDraft(+unitStep)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Theme.azure))
                }
                .buttonStyle(.plain)
            }

            // Slider across the sane range.
            VStack(spacing: 4) {
                Slider(value: Binding(
                    get: { unit.value(fromML: draftGoalML) },
                    set: { newUnitValue in
                        let ml = unit.ml(from: newUnitValue)
                        draftGoalML = (ml / 50).rounded() * 50
                    }
                ), in: unit == .fluidOunces ? 30...170 : 1000...5000, step: unit == .fluidOunces ? 1 : 50)
                .tint(Theme.azure)

                Text(rangeCaption)
                    .font(FlowFont.caption())
                    .foregroundStyle(Theme.labelTertiary)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                Button {
                    Feedback.sipLogged(enabled: store.reminderSettings.hapticsEnabled)
                    store.profile.customGoalML = draftGoalML
                    dismiss()
                } label: {
                    Text("Set \(Int(unit.value(fromML: draftGoalML).rounded())) \(unit.symbol) Goal")
                        .font(FlowFont.headlineSmall())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Capsule().fill(Theme.flowGradient))
                }
                .buttonStyle(.plain)

                Button {
                    Feedback.tick(enabled: store.reminderSettings.hapticsEnabled)
                    store.profile.customGoalML = nil
                    dismiss()
                } label: {
                    Label("Use Profile Recommendation", systemImage: "arrow.clockwise")
                        .font(FlowFont.bodyBold())
                        .foregroundStyle(Theme.brandPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            Button("Cancel") { dismiss() }
                .font(FlowFont.bodyBold())
                .foregroundStyle(Theme.labelSecondary)
                .padding(.bottom, 20)
        }
        .background(Theme.card)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            draftGoalML = store.baseGoalML
        }
    }

    private var unit: VolumeUnit { store.profile.unit }

    private var unitStep: Double {
        unit == .fluidOunces ? VolumeUnit.mlPerOz : 250
    }

    private var rangeCaption: String {
        unit == .fluidOunces ? "30 – 170 oz" : "1,000 – 5,000 ml"
    }

    private func changeDraft(_ delta: Double) {
        Feedback.tick(enabled: store.reminderSettings.hapticsEnabled)
        let next = min(max(draftGoalML + delta, 1000), 5000)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            draftGoalML = next
        }
    }
}

// MARK: - Profile editor

/// Editable profile: name, weight, sex, modifiers, activity, climate, unit.
struct ProfileEditorSheet: View {
    @EnvironmentObject var store: HydrationStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: UserProfile

    init() {
        // Snapshot the live profile; Cancel discards the draft.
        _draft = State(initialValue: UserProfile())
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                weightSection
                sexSection
                lifestyleSection
                goalPreviewSection
            }
            .navigationTitle("Profile & Units")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Keep any manual goal override across profile edits.
                        let goal = store.profile.customGoalML
                        store.completeOnboarding(profile: draft)
                        store.profile.customGoalML = goal
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                draft = store.profile
            }
        }
    }

    private var nameSection: some View {
        Section("Name") {
            TextField("Your Name", text: $draft.name)
        }
    }

    private var weightSection: some View {
        Section("Body Weight") {
            Stepper("\(Int(draft.weightKg)) kg", value: $draft.weightKg, in: 35...200, step: 1)
        }
    }

    private var sexSection: some View {
        Section("Biological Sex") {
            Picker("Sex", selection: $draft.sex) {
                ForEach(BiologicalSex.allCases) { sex in
                    Text(sex.displayName).tag(sex)
                }
            }
            Toggle("Pregnant", isOn: $draft.isPregnant)
            Toggle("Breastfeeding", isOn: $draft.isBreastfeeding)
        }
    }

    private var lifestyleSection: some View {
        Section("Lifestyle") {
            Picker("Activity", selection: $draft.activity) {
                ForEach(ActivityLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }
            Picker("Climate", selection: $draft.climate) {
                ForEach(Climate.allCases) { climate in
                    Text(climate.displayName).tag(climate)
                }
            }
            Picker("Units", selection: $draft.unit) {
                ForEach(VolumeUnit.allCases) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
        }
    }

    private var goalPreviewSection: some View {
        Section {
            let goal = GoalCalculator.dailyGoalML(profile: draft)
            Text("Estimated goal: \(Int(VolumeUnit.fluidOunces.value(fromML: goal).rounded())) fl oz (\(Int(goal)) ml)")
                .font(FlowFont.subhead())
                .foregroundStyle(Theme.brandPrimary)
        }
    }
}

// MARK: - Helpers

extension ReminderSettings {
    /// Formats a date as "10 PM" (hour only).
    static let hourOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f
    }()
}

extension View {
    /// Standard card background for grouped rows.
    func flowCardBackground() -> some View {
        background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.black.opacity(0.04), lineWidth: 0.5)
        )
    }
}
