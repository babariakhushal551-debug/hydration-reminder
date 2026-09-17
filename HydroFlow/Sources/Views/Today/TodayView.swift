import SwiftUI

/// Main dashboard: liquid-glass orb, hydration rhythm pill, quick stats,
/// one-tap quick-log shelf, and today's recent sips feed.
struct TodayView: View {
    @EnvironmentObject var store: HydrationStore
    @Binding var showingLogSheet: Bool

    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                rhythmPill
                orbCard
                quickStatsRow
                quickLogCard
                recentSipsSection
            }
            .padding(.horizontal, .margin)
            .padding(.top, 8)
            .padding(.bottom, 110)
        }
        .background(Theme.canvas)
        .overlay(alignment: .top) {
            if let toast {
                ToastView(text: toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header widgets

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
                Text("Next recommended sip in \(nextSipMinutes) mins")
                    .font(FlowFont.subhead(12.5))
                    .fontWeight(.medium)
            }

            Spacer()

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

    private var orbCard: some View {
        FlowCard {
            VStack(spacing: 14) {
                HydrationOrbView(
                    progress: store.todayProgress,
                    currentML: store.todayTotalML,
                    goalML: store.dailyGoalML,
                    unit: store.profile.unit
                )

                // Encouraging dynamic feedback line.
                HStack(spacing: 6) {
                    Text("💧")
                    Text(feedbackLine)
                        .font(FlowFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.labelSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(Theme.azure.opacity(0.07)))
                .overlay(Capsule().strokeBorder(Theme.azure.opacity(0.14), lineWidth: 0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            FlowCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        IconTile(systemName: "clock", tint: Theme.azure, size: 28)
                        Text("LAST DRINK")
                            .font(FlowFont.caption(10))
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.labelSecondary)
                    }
                    if let last = store.lastEntry {
                        Text(last.beverage.displayName)
                            .font(FlowFont.bodyBold)
                            .lineLimit(1)
                        Text("\(last.date, formatter: Self.agoFormatter) • \(last.containerName ?? "Quick log")")
                            .font(FlowFont.caption)
                            .foregroundStyle(Theme.labelSecondary)
                    } else {
                        Text("No drinks yet")
                            .font(FlowFont.bodyBold)
                        Text("Log your first sip!")
                            .font(FlowFont.caption)
                            .foregroundStyle(Theme.labelSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            FlowCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        IconTile(systemName: "target", tint: Theme.aqua, size: 28)
                        Text("DAILY TARGET")
                            .font(FlowFont.caption(10))
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.labelSecondary)
                    }
                    Text(remainingText)
                        .font(FlowFont.bodyBold)
                    Text(glassesText)
                        .font(FlowFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.aqua)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Quick log

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
                        .font(FlowFont.caption)
                        .foregroundStyle(Theme.labelSecondary)
                }

                // Four vessel chips (Glass, Mug, Bottle, Flask).
                HStack(spacing: 8) {
                    ForEach(QuickLogVessel.defaults) { vessel in
                        QuickVesselButton(vessel: vessel, unit: store.profile.unit) {
                            logQuick(vessel)
                        }
                    }
                }

                HStack(spacing: 10) {
                    // Custom amount → opens the full log sheet.
                    Button {
                        showingLogSheet = true
                    } label: {
                        Label("Custom", systemImage: "slider.horizontal.3")
                            .font(FlowFont.bodyBold(12))
                            .foregroundStyle(Theme.labelSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.azure.opacity(0.07)))
                    }

                    Spacer()

                    // Prominent log action.
                    Button {
                        logQuick(QuickLogVessel.defaults[0])
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(.white.opacity(0.22)))
                            Text("Log Sip")
                                .font(FlowFont.bodyBold(14))
                            Image(systemName: "drop.fill")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(Theme.flowGradient))
                        .shadow(color: Theme.azure.opacity(0.35), radius: 10, y: 4)
                    }

                    Spacer()

                    // Repeat last sip.
                    Button {
                        repeatLast()
                    } label: {
                        Label(repeatLabel, systemImage: "arrow.counterclockwise")
                            .font(FlowFont.bodyBold(12))
                            .foregroundStyle(Theme.labelSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.azure.opacity(0.07)))
                    }
                }
            }
        }
    }

    // MARK: - Recent sips

    private var recentSipsSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Recent Sips Today")
                    .font(FlowFont.bodyBold)
                Text("(\(store.todayEntriesNewestFirst.count) logged)")
                    .font(FlowFont.subhead)
                    .foregroundStyle(Theme.labelSecondary)
                Spacer()
                NavigationLink {
                    HistoryView()
                } label: {
                    HStack(spacing: 2) {
                        Text("View All")
                        Image(systemName: "chevron.right")
                    }
                    .font(FlowFont.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.azure)
                }
            }
            .padding(.horizontal, 4)

            let today = store.todayEntriesNewestFirst
            if today.isEmpty {
                FlowCard {
                    Text("Nothing logged yet today — tap a vessel above to start! 💧")
                        .font(FlowFont.subhead)
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
                        .strokeBorder(Color.black.opacity(0.04), lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Helpers

    private var nextSipMinutes: Int {
        let intervalMinutes = store.reminderSettings.interval.rawValue * 60
        let elapsed = Date().timeIntervalSince(store.lastEntry?.date ?? Date())
        let remaining = max(0, intervalMinutes - elapsed / 60)
        return Int(remaining.rounded())
    }

    private var feedbackLine: String {
        let unit = store.profile.unit
        let remaining = max(0, store.dailyGoalML - store.todayTotalML)
        if remaining <= 0 { return "Goal complete — beautifully done! 🎉" }
        let value = unit.value(fromML: remaining)
        return "\(Int(value.rounded())) \(unit.symbol) remaining to stay fully energized"
    }

    private var remainingText: String {
        let unit = store.profile.unit
        let remaining = max(0, store.dailyGoalML - store.todayTotalML)
        return "\(Int(unit.value(fromML: remaining).rounded())) \(unit.symbol) left"
    }

    private var glassesText: String {
        let remaining = max(0, store.dailyGoalML - store.todayTotalML)
        let glasses = remaining / 240
        return String(format: "approx. %.1f glasses", glasses)
    }

    private var repeatLabel: String {
        guard let last = store.lastEntry else { return "Repeat" }
        let unit = store.profile.unit
        return "+\(Int(unit.value(fromML: last.volumeML).rounded())) \(unit.symbol)"
    }

    private func logQuick(_ vessel: QuickLogVessel) {
        let entry = store.logDrink(vessel.beverage, volumeML: vessel.volumeML, containerName: vessel.name)
        Feedback.sipLogged(enabled: store.reminderSettings.hapticsEnabled)
        HealthKitManager.shared.syncEntry(entry)
        showToast("+\(Int(store.profile.unit.value(fromML: vessel.volumeML).rounded())) \(store.profile.unit.symbol) logged")
    }

    private func repeatLast() {
        guard let last = store.lastEntry else { return }
        let entry = store.logDrink(last.beverage, volumeML: last.volumeML, containerName: last.containerName)
        Feedback.sipLogged(enabled: store.reminderSettings.hapticsEnabled)
        HealthKitManager.shared.syncEntry(entry)
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

    private static let agoFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()
}

// MARK: - Quick log vessels

/// One of the four one-tap vessel chips on the dashboard.
struct QuickLogVessel: Identifiable {
    let id: String
    let name: String
    let beverage: BeverageType
    let volumeML: Double
    let symbol: String

    static let defaults: [QuickLogVessel] = [
        .init(id: "glass", name: "Glass", beverage: .water, volumeML: 240, symbol: "cup.and.saucer.fill"),
        .init(id: "mug", name: "Mug", beverage: .tea, volumeML: 355, symbol: "mug.fill"),
        .init(id: "bottle", name: "Bottle", beverage: .water, volumeML: 473, symbol: "bottle.fill"),
        .init(id: "flask", name: "Flask", beverage: .electrolytes, volumeML: 710, symbol: "takeoutbag.and.cup.and.straw.fill")
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
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
                    Image(systemName: vessel.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.azure)
                }
                .frame(width: 40, height: 40)

                Text("+\(Int(unit.value(fromML: vessel.volumeML).rounded())) \(unit.symbol)")
                    .font(FlowFont.bodyBold(12))
                    .foregroundStyle(Theme.labelPrimary)
                Text(vessel.name)
                    .font(FlowFont.caption(10))
                    .foregroundStyle(Theme.labelSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
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
                        .font(FlowFont.bodyBold)
                        .lineLimit(1)
                    Text("\(Int(entry.hydrationFactor * 100))%")
                        .font(FlowFont.caption(10))
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.azure)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.azure.opacity(0.10)))
                }
                Text("\(entry.date, formatter: Self.timeFormatter) • \(entry.containerName ?? entry.beverage.displayName)")
                    .font(FlowFont.caption)
                    .foregroundStyle(Theme.labelSecondary)
            }

            Spacer()

            Text("+\(Int(unit.value(fromML: entry.volumeML).rounded())) \(unit.symbol)")
                .font(FlowFont.subhead)
                .fontWeight(.bold)
                .foregroundStyle(Theme.azure)

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
