import SwiftUI

/// "Reminders & Preferences": smart hydration alerts, sounds & haptics,
/// targets & HealthKit integration, and data controls.
struct SettingsView: View {
    @EnvironmentObject var store: HydrationStore
    @EnvironmentObject var notificationScheduler: NotificationScheduler

    @State private var showGoalEditor = false
    @State private var showIntervalPicker = false
    @State private var showActiveHoursPicker = false
    @State private var showProfileEditor = false
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
        }
        .background(Theme.canvas)
        .navigationTitle("Reminders & Preferences")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showGoalEditor) { goalEditor }
        .sheet(isPresented: $showIntervalPicker) { intervalPicker }
        .sheet(isPresented: $showActiveHoursPicker) { activeHoursPicker }
        .sheet(isPresented: $showProfileEditor) { profileEditor }
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
        let time = ReminderSettings.hourFormatter.string(from: nextAlertDate)
        return "Today at \(time) · \(Int(store.profile.unit.value(fromML: 240).rounded())) \(store.profile.unit.symbol)"
    }

    private var nextAlertDate: Date {
        Calendar.current.date(byAdding: .hour, value: Int(store.reminderSettings.interval.rawValue),
                              to: Date()) ?? Date()
    }

    private var bannerBadge: String {
        store.reminderSettings.remindersEnabled && !store.reminderSettings.bedtimeMode
            ? "On Schedule"
            : "Paused"
    }

    // MARK: - Sections

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
                Divider().padding(.leading, 54)

                NavigationRow(
                    icon: "timer", iconTint: Theme.aqua,
                    title: "Reminder Interval"
                ) {
                    Text(store.reminderSettings.interval.displayName)
                        .font(FlowFont.subhead())
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.brandPrimary)
                }
                .contentShape(Rectangle())
                .onTapGesture { showIntervalPicker = true }
                Divider().padding(.leading, 54)

                NavigationRow(
                    icon: "clock", iconTint: Theme.indigo,
                    title: "Active Hours"
                ) {
                    Text(activeHoursText)
                        .font(FlowFont.subhead())
                        .foregroundStyle(Theme.labelSecondary)
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
                Divider().padding(.leading, 54)

                ToggleRow(
                    icon: "sun.max.fill", iconTint: .orange,
                    title: "Dynamic Weather",
                    subtitle: weatherSubtitle,
                    isOn: $store.reminderSettings.dynamicWeather
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .flowCardBackground()
        }
    }

    private var soundsSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Sounds & Haptics")
            VStack(spacing: 0) {
                NavigationRow(
                    icon: "speaker.wave.2.fill", iconTint: Theme.aqua,
                    title: "Notification Sound"
                ) {
                    Text("Gentle Ripple")
                        .font(FlowFont.subhead())
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.brandPrimary)
                }
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

    private var targetsSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Targets & Integration")
            VStack(spacing: 0) {
                NavigationRow(
                    icon: "flag.fill", iconTint: Theme.azure,
                    title: "Daily Goal",
                    subtitle: "Tap to recalculate metabolic baseline"
                ) {
                    Text("\(Int(store.profile.unit.value(fromML: store.dailyGoalML).rounded())) \(store.profile.unit.symbol)")
                        .font(FlowFont.headlineSmall())
                        .foregroundStyle(Theme.brandPrimary)
                }
                .contentShape(Rectangle())
                .onTapGesture { showGoalEditor = true }
                Divider().padding(.leading, 54)

                NavigationRow(
                    icon: "heart.fill", iconTint: Theme.destructive,
                    title: "Apple Health Sync",
                    subtitle: "Syncs water intake to HealthKit"
                ) {
                    HStack(spacing: 6) {
                        Circle().fill(Theme.success).frame(width: 8, height: 8)
                        Text(healthStatusText)
                            .font(FlowFont.subhead())
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.success)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { Task { await connectHealth() } }
                Divider().padding(.leading, 54)

                NavigationRow(
                    icon: "record.circle.fill", iconTint: Theme.indigo,
                    title: "Container Presets",
                    subtitle: "Hydro Flask (24 oz), Cup (8 oz)"
                ) {
                    EmptyView()
                }
                Divider().padding(.leading, 54)

                NavigationRow(
                    icon: "figure.arms.open", iconTint: .orange,
                    title: "Profile & Units",
                    subtitle: "Weight, activity, climate, ml/oz"
                ) {
                    EmptyView()
                }
                .contentShape(Rectangle())
                .onTapGesture { showProfileEditor = true }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .flowCardBackground()
        }
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
                Text("HydroFlow v1.0 (Build 1)")
                Text("Designed with Apple HealthKit Integration")
            }
            .font(FlowFont.caption())
            .foregroundStyle(Theme.labelTertiary)
        }
    }

    // MARK: - Sheets

    private var goalEditor: some View {
        GoalEditorSheet()
            .presentationDetents([.medium])
    }

    private var intervalPicker: some View {
        VStack(spacing: 0) {
            ForEach(ReminderInterval.allCases) { interval in
                intervalRow(interval)
                Divider().padding(.leading, 20)
            }
        }
        .presentationDetents([.medium])
        .background(Theme.card)
    }

    private func intervalRow(_ interval: ReminderInterval) -> some View {
        Button {
            store.reminderSettings.interval = interval
            rescheduleNotifications()
            showIntervalPicker = false
        } label: {
            HStack {
                Text(interval.displayName)
                    .font(FlowFont.bodyBold())
                    .foregroundStyle(Theme.labelPrimary)
                Spacer()
                if store.reminderSettings.interval == interval {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.azure)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var activeHoursPicker: some View {
        VStack(spacing: 16) {
            Text("Active Hours")
                .font(FlowFont.headline())
            HStack(spacing: 16) {
                hourPicker(title: "From", selection: $store.reminderSettings.activeStartHour)
                Image(systemName: "arrow.right")
                    .foregroundStyle(Theme.labelTertiary)
                hourPicker(title: "To", selection: $store.reminderSettings.activeEndHour)
            }
            saveHoursButton
        }
        .padding(.top, 24)
        .presentationDetents([.height(280)])
        .background(Theme.card)
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

    private func hourPicker(title: String, selection: Binding<Int>) -> some View {
        Picker(title, selection: selection) {
            ForEach(6..<24, id: \.self) { hour in
                Text(ReminderSettings.hourFormatter.string(from: Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()))
                    .tag(hour)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
    }

    private var profileEditor: some View {
        ProfileEditorSheet()
    }

    // MARK: - Logic

    private var activeHoursText: String {
        "\(ReminderSettings.hourFormatter.string(from: store.reminderSettings.activeStart)) – \(ReminderSettings.hourOnlyFormatter.string(from: store.reminderSettings.activeEnd))"
    }

    private var weatherSubtitle: String {
        WeatherProviding.isHotDay() ? "Hot day detected — bonus active!" : "Auto-adds +12 oz on high heat days"
    }

    private var healthStatusText: String {
        HealthKitManager.shared.isAvailable ? "Connected" : "Unavailable"
    }

    private func connectHealth() async {
        _ = await HealthKitManager.shared.requestAuthorization()
    }

    private func rescheduleNotifications() {
        notificationScheduler.reschedule(settings: store.reminderSettings)
    }
}

// MARK: - Goal editor

/// Manual daily-goal override sheet (recompute from profile).
struct GoalEditorSheet: View {
    @EnvironmentObject var store: HydrationStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Daily Goal")
                    .font(FlowFont.headline())
                Text("Recalculated from your profile: \(Int(store.profile.unit.value(fromML: GoalCalculator.dailyGoalML(profile: store.profile)).rounded())) \(store.profile.unit.symbol)")
                    .font(FlowFont.subhead())
                    .foregroundStyle(Theme.labelSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            Button {
                store.refreshWeatherBonus()
                dismiss()
            } label: {
                Label("Use Profile Recommendation", systemImage: "arrow.clockwise")
                    .font(FlowFont.headlineSmall())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Capsule().fill(Theme.flowGradient))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Button("Cancel") { dismiss() }
                .font(FlowFont.bodyBold())
                .foregroundStyle(Theme.brandPrimary)
                .padding(.bottom, 20)
        }
        .background(Theme.card)
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
                        store.completeOnboarding(profile: draft)
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
