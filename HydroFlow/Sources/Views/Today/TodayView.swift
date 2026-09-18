import SwiftUI

/// Main dashboard (final design): header with streak, hydration rhythm card,
/// bottle hero, quick stats, one-tap quick-log shelf, and today's sips feed.
/// Scroll is strictly vertical; every row is width-constrained so nothing can
/// push the layout sideways.
struct TodayView: View {
    @EnvironmentObject var store: HydrationStore
    @Binding var showingLogSheet: Bool

    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var showGoalSheet = false
    /// Ticks every 15 s so time-relative UI ("next sip in X min") is dynamic
    /// instead of frozen at whatever value it had on the last render.
    @State private var now = Date()

    private static let clockTicker = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    var body: some View {
        // `.vertical` only — this is the fix for the whole tab drifting
        // horizontally when content overflows.
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                headerRow
                rhythmPill
                bottleHeroCard
                quickStatsRow
                quickLogCard
                recentSipsSection
            }
            .padding(.horizontal, .margin)
            .padding(.top, 8)
            .padding(.bottom, 110)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.canvas)
        .onReceive(Self.clockTicker) { date in
            now = date
        }
        .overlay(alignment: .top) {
            if let toast {
                ToastView(text: toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showGoalSheet) {
            GoalEditorSheet()
                .presentationDetents([.medium])
        }
    }

    // MARK: - Header (greeting + streak + quick links)

    private var headerRow: some View {
        HStack(spacing: 12) {
            // Leading app tile.
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.azure.opacity(0.12))
                Image(systemName: "drop.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.azure)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("Today, \(Self.dateFormatter.string(from: Date()))")
                    .font(FlowFont.bodyBold(15))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.orange)
                    Text(streakText)
                        .font(FlowFont.caption(11.5))
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    Text("• Top \(topPercent)")
                        .font(FlowFont.caption(11.5))
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.labelSecondary)
                }
            }

            Spacer(minLength: 8)

            // Goal quick-adjust: − / value / + (tap value to open editor).
            goalStepper

            NavigationLink { AnalyticsView() } label: {
                Image(systemName: "calendar_month")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.labelPrimary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.card))
                    .overlay(Circle().strokeBorder(Theme.hairline.opacity(0.5), lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            // Light/Dark quick toggle (cycles System → Light → Dark).
            Button {
                Feedback.tick(enabled: store.reminderSettings.hapticsEnabled)
                withAnimation(.easeInOut(duration: 0.25)) {
                    store.appearance = store.appearance.next
                }
            } label: {
                Image(systemName: store.appearance.symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.labelPrimary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.card))
                    .overlay(Circle().strokeBorder(Theme.hairline.opacity(0.5), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Appearance: \(store.appearance.displayName). Double tap to switch.")
        }
    }

    /// Compact −/goal/+ control letting the user raise or lower the daily
    /// goal right from the dashboard (step: 1 glass = 250 ml).
    private var goalStepper: some View {
        HStack(spacing: 6) {
            Button {
                adjustGoal(by: -250)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.labelPrimary)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Theme.card))
                    .overlay(Circle().strokeBorder(Theme.hairline.opacity(0.6), lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            Button {
                showGoalSheet = true
            } label: {
                Text(goalText)
                    .font(FlowFont.caption(11.5))
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(Theme.brandPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Daily goal \(goalText). Double tap to edit.")

            Button {
                adjustGoal(by: 250)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Theme.azure))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Rhythm card

    private var rhythmPill: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.azure)
                Image(systemName: "drop.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("HYDRATION RHYTHM")
                        .font(FlowFont.caption(10))
                        .fontWeight(.bold)
                        .tracking(0.6)
                        .foregroundStyle(Theme.azure)
                    Text("• Optimal")
                        .font(FlowFont.caption(10))
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.aqua)
                }
                Text(rhythmText)
                    .font(FlowFont.subhead(12.5))
                    .fontWeight(.medium)
            }

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.labelTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Theme.azure.opacity(0.10), Theme.aqua.opacity(0.10), Theme.card],
                                     startPoint: .leading, endPoint: .trailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.azure.opacity(0.18), lineWidth: 0.5)
        )
    }

    // MARK: - Bottle hero

    private var bottleHeroCard: some View {
        FlowCard {
            VStack(spacing: 14) {
                BottleFillView(
                    progress: store.todayProgress,
                    currentML: store.todayTotalML,
                    goalML: store.dailyGoalML,
                    unit: store.profile.unit
                )

                HStack(spacing: 6) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.azure)
                    Text(feedbackLine)
                        .font(FlowFont.caption())
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.labelSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(Theme.azure.opacity(0.07)))
                .overlay(Capsule().strokeBorder(Theme.azure.opacity(0.14), lineWidth: 0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Quick stats

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            statCard(icon: "clock.fill", tint: Theme.azure, eyebrow: "LAST DRINK") {
                if let last = store.lastEntry {
                    Text("\(Int(store.profile.unit.value(fromML: last.volumeML).rounded())) \(store.profile.unit.symbol) \(last.beverage.displayName)")
                        .font(FlowFont.bodyBold(14))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("\(last.date, formatter: Self.agoFormatter) • \(last.containerName ?? "Quick log")")
                        .font(FlowFont.caption(10.5))
                        .foregroundStyle(Theme.labelSecondary)
                        .lineLimit(1)
                } else {
                    Text("No drinks yet")
                        .font(FlowFont.bodyBold(14))
                    Text("Log your first sip!")
                        .font(FlowFont.caption(10.5))
                        .foregroundStyle(Theme.labelSecondary)
                }
            }

            statCard(icon: "chart.pie.fill", tint: Theme.aqua, eyebrow: "DAILY TARGET") {
                Text(remainingText)
                    .font(FlowFont.bodyBold(14))
                    .lineLimit(1)
                Text(glassesText)
                    .font(FlowFont.caption(10.5))
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.success)
                    .lineLimit(1)
            }
        }
    }

    private func statCard<Content: View>(icon: String, tint: Color, eyebrow: String,
                                         @ViewBuilder content: () -> Content) -> some View {
        FlowCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    IconTile(systemName: icon, tint: tint, size: 28)
                    Text(eyebrow)
                        .font(FlowFont.caption(10))
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.labelSecondary)
                }
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick log shelf

    private var quickLogCard: some View {
        FlowCard {
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.azure)
                        Text("Quick One-Tap Log")
                            .font(FlowFont.bodyBold(14))
                    }
                    Spacer()
                    Text("Instant Add")
                        .font(FlowFont.caption())
                        .foregroundStyle(Theme.labelSecondary)
                }

                // Vessels from Settings → Container Presets (add/remove/edit there).
                // Grid keeps every chip on an equal track — no sideways overflow.
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                          spacing: 8) {
                    ForEach(store.quickLogVessels) { vessel in
                        QuickVesselButton(vessel: vessel, unit: store.profile.unit) {
                            logQuick(vessel)
                        }
                    }
                }

                // Bottom action row: Custom | Log Sip (horizontal pill) | Repeat.
                HStack(spacing: 8) {
                    Button {
                        showingLogSheet = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Custom")
                                .font(FlowFont.caption(10.5))
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Theme.labelSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.azure.opacity(0.07)))
                    }
                    .buttonStyle(.plain)

                    // The main CTA — fixed horizontal layout.
                    Button {
                        logDefaultVessel()
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(.white.opacity(0.25)))
                            Text("Log Sip")
                                .font(FlowFont.bodyBold(14))
                                .fixedSize(horizontal: true, vertical: false)
                            Image(systemName: "drop.fill")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Theme.flowGradient))
                        .shadow(color: Theme.azure.opacity(0.35), radius: 10, y: 4)
                        .fixedSize()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Log a sip")

                    Button {
                        repeatLast()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 15, weight: .semibold))
                            Text(repeatLabel)
                                .font(FlowFont.caption(10.5))
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(Theme.labelSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.azure.opacity(0.07)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Recent sips

    private var recentSipsSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                Text("Recent Sips Today")
                    .font(FlowFont.bodyBold())
                Text("(\(store.todayEntriesNewestFirst.count) logged)")
                    .font(FlowFont.subhead())
                    .foregroundStyle(Theme.labelSecondary)
                    .lineLimit(1)
                Spacer()
                NavigationLink {
                    HistoryView()
                } label: {
                    HStack(spacing: 2) {
                        Text("View All")
                        Image(systemName: "chevron.right")
                    }
                    .font(FlowFont.caption())
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.azure)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            let today = store.todayEntriesNewestFirst
            if today.isEmpty {
                FlowCard {
                    Text("Nothing logged yet today — tap a vessel above to start! 💧")
                        .font(FlowFont.subhead())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.labelSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(today.prefix(4).enumerated()), id: \.element.id) { index, entry in
                        EntryRow(entry: entry, unit: store.profile.unit)
                        if index < min(today.count, 4) - 1 {
                            Divider().padding(.leading, 54)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: .cardRadius, style: .continuous).fill(Theme.card))
                .overlay(
                    RoundedRectangle(cornerRadius: .cardRadius, style: .continuous)
                        .strokeBorder(Theme.hairline.opacity(0.5), lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Helpers

    private var unit: VolumeUnit { store.profile.unit }

    private var goalText: String {
        "\(Int(unit.value(fromML: store.baseGoalML).rounded()))\(unit.symbol)"
    }

    private var streakText: String {
        let s = store.currentStreak
        return "\(s) Day Streak"
    }

    private var topPercent: String {
        // Gamified tier from streak length (deterministic, offline).
        switch store.currentStreak {
        case 30...: return "1%"
        case 14..<30: return "5%"
        case 7..<14: return "10%"
        case 3..<7: return "25%"
        default: return "50%"
        }
    }

    /// BUG FIX: the pill previously counted *time since the last drink*, so it
    /// froze at "Sip time" once the interval elapsed and never matched when
    /// notifications actually fire. It now uses the SAME slot math as the
    /// scheduler (wall-clock slots) and counts down against the ticking clock.
    private var rhythmText: String {
        let s = store.reminderSettings
        guard s.remindersEnabled, !s.bedtimeMode else { return "Reminders paused — enable them in Settings" }
        let slots = NotificationScheduler.plannedReminderTimes(settings: s)
            .map { $0.hour * 60 + $0.minute }
            .sorted()
        guard !slots.isEmpty else { return "No reminder slots in the active window" }

        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: now)
        let nowMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        // First slot still ahead today; otherwise the earliest slot tomorrow.
        let next = slots.first(where: { $0 > nowMinutes }) ?? slots[0]
        let delta = next > nowMinutes ? next - nowMinutes : (24 * 60 - nowMinutes) + next
        if delta <= 1 { return "Sip time — grab some water now 💧" }

        let hours = delta / 60
        let mins = delta % 60
        let countdown = hours > 0 ? "\(hours) h \(mins) min" : "\(mins) min"
        let clock = String(format: "%d:%02d", next / 60, next % 60)
        return "Next sip in \(countdown) — at \(clock)"
    }

    private var feedbackLine: String {
        let remaining = max(0, store.dailyGoalML - store.todayTotalML)
        if remaining <= 0 { return "Goal complete — beautifully done! 🎉" }
        return "\(Int(unit.value(fromML: remaining).rounded())) \(unit.symbol) remaining to stay fully energized"
    }

    private var remainingText: String {
        let remaining = max(0, store.dailyGoalML - store.todayTotalML)
        return "\(Int(unit.value(fromML: remaining).rounded())) \(unit.symbol) left"
    }

    private var glassesText: String {
        let remaining = max(0, store.dailyGoalML - store.todayTotalML)
        return String(format: "approx. %.1f glasses", remaining / 240)
    }

    private var repeatLabel: String {
        guard let last = store.lastEntry else { return "Repeat" }
        return "+\(Int(unit.value(fromML: last.volumeML).rounded())) \(unit.symbol)"
    }

    /// Raise/lower the goal by `deltaML`, clamped to a sane 1000–5000 ml band.
    private func adjustGoal(by deltaML: Double) {
        let newGoal = min(max(store.baseGoalML + Double(deltaML), 1000), 5000)
        guard abs(newGoal - store.baseGoalML) > 0.5 else { return }
        Feedback.tick(enabled: store.reminderSettings.hapticsEnabled)
        store.profile.customGoalML = newGoal
        let value = Int(unit.value(fromML: newGoal).rounded())
        showToast("Daily goal set to \(value) \(unit.symbol)")
    }

    private func logQuick(_ vessel: QuickLogVessel) {
        _ = store.logDrink(vessel.beverage, volumeML: vessel.volumeML, containerName: vessel.name)
        Feedback.sipLogged(enabled: store.reminderSettings.hapticsEnabled)
        showToast("+\(Int(unit.value(fromML: vessel.volumeML).rounded())) \(unit.symbol) logged")
    }

    private func logDefaultVessel() {
        let vessel = store.quickLogVessels.first ?? QuickLogVessel.defaults[0]
        logQuick(vessel)
    }

    private func repeatLast() {
        guard let last = store.lastEntry else {
            showToast("Nothing to repeat yet")
            return
        }
        _ = store.logDrink(last.beverage, volumeML: last.volumeML, containerName: last.containerName)
        Feedback.sipLogged(enabled: store.reminderSettings.hapticsEnabled)
        showToast("Repeated last sip")
    }

    private func showToast(_ text: String) {
        toastTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            toast = text
        }
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    toast = nil
                }
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let agoFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()
}

// MARK: - Quick log vessels

/// One of the one-tap vessel chips on the dashboard (mirrors a ContainerPreset).
struct QuickLogVessel: Identifiable {
    let id: String
    let name: String
    let beverage: BeverageType
    let volumeML: Double
    let symbol: String

    static let defaults: [QuickLogVessel] = [
        .init(id: "glass", name: "Glass", beverage: .water, volumeML: 240, symbol: "water.glass.fill"),
        .init(id: "mug", name: "Mug", beverage: .tea, volumeML: 355, symbol: "mug.fill"),
        .init(id: "bottle", name: "Bottle", beverage: .water, volumeML: 473, symbol: "waterbottle.fill"),
        .init(id: "flask", name: "Flask", beverage: .electrolytes, volumeML: 710, symbol: "testtube.fill")
    ]
}

/// Vessel chip button with icon tile + volume caption.
struct QuickVesselButton: View {
    let vessel: QuickLogVessel
    let unit: VolumeUnit
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Theme.hairline.opacity(0.6), lineWidth: 0.5)
                        )
                        .shadow(color: Theme.azure.opacity(0.10), radius: 3, y: 1)
                    Image(systemName: vessel.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.azure)
                }
                .frame(width: 40, height: 40)

                Text("+\(Int(unit.value(fromML: vessel.volumeML).rounded())) \(unit.symbol)")
                    .font(FlowFont.bodyBold(12))
                    .foregroundStyle(Theme.labelPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(vessel.name)
                    .font(FlowFont.caption(10))
                    .foregroundStyle(Theme.labelSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.azure.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.azure.opacity(0.14), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Entry row

/// A logged drink row with beverage tile, hydration %, time, and volume.
struct EntryRow: View {
    let entry: WaterEntry
    let unit: VolumeUnit
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemName: entry.beverage.symbolName, tint: Theme.azure, size: 36)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(FlowFont.bodyBold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(Int(entry.hydrationFactor * 100))%")
                        .font(FlowFont.caption(10))
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.azure)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.azure.opacity(0.10)))
                }
                Text("\(entry.date, formatter: Self.timeFormatter) • \(entry.containerName ?? entry.beverage.displayName)")
                    .font(FlowFont.caption())
                    .foregroundStyle(Theme.labelSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Text("+\(Int(unit.value(fromML: entry.volumeML).rounded())) \(unit.symbol)")
                .font(FlowFont.subhead())
                .fontWeight(.bold)
                .foregroundStyle(Theme.azure)
                .fixedSize()

            if let onDelete {
                Menu {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete Entry", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.labelTertiary)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var title: String {
        "\(Int(unit.value(fromML: entry.volumeML).rounded())) \(unit.symbol) \(entry.beverage.displayName)"
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}
