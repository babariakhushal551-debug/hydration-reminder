import SwiftUI

/// "Hydration Insights": weekly summary, interactive bar chart, day detail
/// timeline, and a monthly consistency heat-map.
struct AnalyticsView: View {
    @EnvironmentObject var store: HydrationStore

    @State private var selectedDay: Date?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                summaryCard
                weeklyChartCard
                dayDetailCard
                heatmapCard
            }
            .padding(.horizontal, .margin)
            .padding(.top, 8)
            .padding(.bottom, 110)
        }
        .background(Theme.canvas)
        .navigationTitle("Hydration Insights")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header row

    private var header: some View {
        HStack {
            Spacer()
            Text(weekRangeText)
                .font(FlowFont.caption)
                .foregroundStyle(Theme.labelTertiary)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        let avg = StatsEngine.weekAverageML(reference: Date(), entries: store.entries)
        let change = StatsEngine.weekOverWeekChange(reference: Date(), entries: store.entries)

        return FlowCard {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("WEEKLY METRIC")
                        .font(FlowFont.caption(10))
                        .fontWeight(.bold)
                        .tracking(0.6)
                        .foregroundStyle(Theme.brandPrimary)
                    Text("\(daysMet) / 7 Days Goal Met")
                        .font(FlowFont.headline)
                    HStack(spacing: 8) {
                        Text("Daily Avg:")
                            .font(FlowFont.subhead)
                            .foregroundStyle(Theme.labelSecondary)
                        Text("\(Int(unit.value(fromML: avg).rounded())) \(unit.symbol)")
                            .font(FlowFont.bodyBold)
                            .foregroundStyle(Theme.brandPrimary)
                        if let change {
                            Text(String(format: "%+.0f%% vs lw", change))
                                .font(FlowFont.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(change >= 0 ? Theme.success : Theme.destructive)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(change >= 0 ? Theme.success.opacity(0.12) : Theme.destructive.opacity(0.10)))
                        }
                    }
                }
                Spacer()

                // Glowing checkmark badge.
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.aqua.opacity(0.20))
                        .frame(width: 52, height: 52)
                        .shadow(color: Theme.aqua.opacity(0.45), radius: 12)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Theme.aqua)
                }
            }
        }
    }

    // MARK: - Weekly chart

    private var weeklyChartCard: some View {
        FlowCard {
            VStack(spacing: 14) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bar.chart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.azure)
                        Text("Weekly Intake Trend")
                            .font(FlowFont.headlineSmall)
                    }
                    Spacer()
                    Text("Target: \(Int(unit.value(fromML: store.dailyGoalML).rounded())) \(unit.symbol)")
                        .font(FlowFont.caption)
                        .foregroundStyle(Theme.labelTertiary)
                }

                WeeklyBarChart(
                    reference: Date(),
                    entries: store.entries,
                    goalML: store.dailyGoalML,
                    unit: unit
                )
            }
        }
    }

    // MARK: - Day detail

    private var dayDetailCard: some View {
        let day = selectedDay ?? lastDayWithData
        let total = StatsEngine.totalML(on: day, from: store.entries)
        let dayEntries = StatsEngine.entries(on: day, from: store.entries).sorted { $0.date < $1.date }

        return FlowCard {
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Theme.azure)
                            .frame(width: 10, height: 10)
                            .background(Circle().strokeBorder(Theme.azure.opacity(0.25), lineWidth: 4))
                        Text("\(day, formatter: Self.dayFormatter) Breakdown")
                            .font(FlowFont.headlineSmall)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(Int(unit.value(fromML: total).rounded())) / \(Int(unit.value(fromML: store.dailyGoalML).rounded())) \(unit.symbol)")
                            .font(FlowFont.bodyBold)
                            .foregroundStyle(Theme.brandPrimary)
                        Text(percentText(total))
                            .font(FlowFont.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.success)
                    }
                }

                if dayEntries.isEmpty {
                    Text("No entries for this day.")
                        .font(FlowFont.subhead)
                        .foregroundStyle(Theme.labelTertiary)
                        .padding(.vertical, 10)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(dayEntries.enumerated()), id: \.element.id) { index, entry in
                            TimelineEntryRow(entry: entry, unit: unit)
                            if index < dayEntries.count - 1 {
                                Divider().padding(.leading, 46)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Heatmap

    private var heatmapCard: some View {
        let heatmap = StatsEngine.monthHeatmap(year: currentYear, month: currentMonth,
                                               goalML: store.dailyGoalML, entries: store.entries)
        let metDays = heatmap.values.filter { $0 >= 1.0 }.count

        return FlowCard {
            VStack(spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.aqua)
                        Text("\(Self.monthFormatter.string(from: Date())) Consistency")
                            .font(FlowFont.headlineSmall)
                    }
                    Spacer()
                    HStack(spacing: 2) {
                        Text("\(metDays) / \(heatmap.count) days")
                            .font(FlowFont.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.brandPrimary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }

                Text("Heat-map indicator across daily hydration goals")
                    .font(FlowFont.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Theme.labelSecondary)

                MonthHeatmapGrid(heatmap: heatmap, unit: unit)
                    .padding(.top, 2)

                // Legend.
                HStack(spacing: 14) {
                    Spacer()
                    legendSwatch(color: Theme.indigo.opacity(0.35), label: "<80%")
                    legendSwatch(color: Theme.aqua.opacity(0.75), label: "80–99%")
                    legendSwatch(color: Theme.aqua, label: "100%+ Met")
                }
                .font(FlowFont.caption)
                .foregroundStyle(Theme.labelTertiary)
            }
        }
    }

    // MARK: - Helpers

    private var unit: VolumeUnit { store.profile.unit }

    private var daysMet: Int {
        StatsEngine.daysGoalMetInWeek(reference: Date(), goalML: store.dailyGoalML, entries: store.entries)
    }

    private var lastDayWithData: Date {
        let withData = store.entries.map { Calendar.current.startOfDay(for: $0.date) }.max()
        return withData ?? Date()
    }

    private var weekRangeText: String {
        let days = StatsEngine.weekDays(reference: Date())
        guard days.count == 7 else { return "" }
        return "\(Self.rangeFormatter.string(from: days[0])) – \(Self.rangeFormatter.string(from: days[6]))"
    }

    private var currentYear: Int {
        Calendar.current.dateComponents([.year], from: Date()).year ?? 2026
    }

    private var currentMonth: Int {
        Calendar.current.dateComponents([.month], from: Date()).month ?? 1
    }

    private func percentText(_ total: Double) -> String {
        let pct = store.dailyGoalML > 0 ? Int((total / store.dailyGoalML * 100).rounded()) : 0
        return "(\(pct)%)"
    }

    private func legendSwatch(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    private static let rangeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f
    }()
}

// MARK: - Weekly bar chart

/// Custom-drawn weekly bars with dashed goal line, "Today" marker, and
/// dashed placeholders for future days (mockup parity).
struct WeeklyBarChart: View {
    let reference: Date
    let entries: [WaterEntry]
    let goalML: Double
    let unit: VolumeUnit

    private var totals: [(day: Date, value: Double)] {
        StatsEngine.weekDays(reference: reference)
            .map { ($0, StatsEngine.totalML(on: $0, from: entries)) }
    }

    var body: some View {
        VStack(spacing: 6) {
            // Dashed goal line.
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Theme.azure.opacity(0.30))
                    .frame(height: 1)
                Text("\(Int(unit.value(fromML: goalML).rounded())) \(unit.symbol)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.brandPrimary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Theme.canvas))
            }
            .frame(height: 16)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(totals.enumerated()), id: \.element.day) { index, item in
                    DayBar(
                        date: item.day,
                        totalML: item.value,
                        goalML: goalML,
                        unit: unit,
                        isToday: Calendar.current.isDateInToday(item.day),
                        isFuture: item.day > Date(),
                        appearanceDelay: Double(index) * 0.05
                    )
                }
            }
        }
        .frame(height: 176)
    }
}

/// One bar in the weekly chart.
private struct DayBar: View {
    let date: Date
    let totalML: Double
    let goalML: Double
    let unit: VolumeUnit
    let isToday: Bool
    let isFuture: Bool
    var appearanceDelay: Double = 0

    @State private var appeared = false

    private var maxHeight: CGFloat { 118 }

    private var fillFraction: CGFloat {
        guard goalML > 0 else { return 0 }
        return min(CGFloat(totalML / goalML), 1)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(barLabel)
                .font(.system(size: 10, weight: isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(isToday ? Theme.brandPrimary : Theme.labelSecondary)

            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Theme.azure.opacity(0.08))
                    .frame(height: maxHeight)

                if isFuture {
                    Capsule()
                        .fill(Theme.labelTertiary.opacity(0.15))
                        .frame(height: 24)
                        .overlay(Capsule().strokeBorder(style: StrokeStyle(lineWidth: 0.8, dash: [3])).foregroundStyle(Theme.labelTertiary))
                        .padding(.bottom, 0)
                } else {
                    Capsule()
                        .fill(barGradient)
                        .frame(height: max(6, fillFraction * maxHeight))
                        .shadow(color: isToday ? Theme.azure.opacity(0.45) : .clear, radius: 8)
                        .scaleEffect(y: appeared ? 1 : 0, anchor: .bottom)
                }
            }
            .frame(height: maxHeight)

            Text(weekdayLetter)
                .font(FlowFont.caption)
                .fontWeight(isToday ? .bold : .medium)
                .foregroundStyle(isToday ? Theme.brandPrimary : Theme.labelSecondary)
        }
        .opacity(isFuture ? 0.55 : 1)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(appearanceDelay)) {
                appeared = true
            }
        }
    }

    private var barLabel: String {
        isFuture ? "--" : "\(Int(unit.value(fromML: totalML).rounded()))"
    }

    private var weekdayLetter: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEEE"
        return fmt.string(from: date)
    }

    private var barGradient: LinearGradient {
        if isToday {
            return LinearGradient(colors: [Theme.azure, Theme.azure.opacity(0.8)], startPoint: .bottom, endPoint: .top)
        }
        return fillFraction >= 1
            ? LinearGradient(colors: [Theme.aqua, Theme.aqua.opacity(0.7)], startPoint: .bottom, endPoint: .top)
            : LinearGradient(colors: [Theme.indigo.opacity(0.55), Theme.indigo.opacity(0.3)], startPoint: .bottom, endPoint: .top)
    }
}

// MARK: - Timeline row (day breakdown)

/// Compact timeline row used in the day-detail breakdown card.
struct TimelineEntryRow: View {
    let entry: WaterEntry
    let unit: VolumeUnit

    var body: some View {
        HStack(spacing: 10) {
            IconTile(systemName: symbol, tint: tint, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(periodName)
                    .font(FlowFont.subhead)
                    .fontWeight(.semibold)
                Text("\(entry.date, formatter: Self.timeFormatter) • \(entry.containerName ?? entry.beverage.displayName)")
                    .font(FlowFont.caption)
                    .foregroundStyle(Theme.labelSecondary)
            }

            Spacer()

            Text("+\(Int(unit.value(fromML: entry.volumeML).rounded())) \(unit.symbol)")
                .font(FlowFont.bodyBold)
        }
        .padding(.vertical, 5)
    }

    private var symbol: String {
        switch Calendar.current.component(.hour, from: entry.date) {
        case 5..<11: "sun.max.fill"
        case 11..<14: "sun.and.horizon.fill"
        case 14..<18: "figure.run"
        case 18..<21: "fork.knife"
        default: "moon.stars.fill"
        }
    }

    private var tint: Color {
        entry.hydrationFactor >= 1.0 ? Theme.azure :
            entry.beverage == .electrolytes ? Theme.aqua : Theme.indigo
    }

    private var periodName: String {
        switch Calendar.current.component(.hour, from: entry.date) {
        case 5..<11: "Morning Boost"
        case 11..<14: "Midday Water"
        case 14..<18: "Afternoon Refill"
        case 18..<21: "Dinner Hydration"
        default: "Evening Sip"
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}

// MARK: - Month heatmap grid

/// 7-column month heat-map with day numbers, today ring, and future dashes.
struct MonthHeatmapGrid: View {
    let heatmap: [Date: Double]
    let unit: VolumeUnit

    var body: some View {
        let days = heatmap.keys.sorted()
        let leadingBlanks = days.first.map { Calendar.current.component(.weekday, from: $0) - 2 } ?? 0
        // Normalize Monday-first index (weekday 1 = Sunday → 6).
        let normalizedBlanks = (leadingBlanks + 7) % 7

        VStack(spacing: 5) {
            // Weekday header.
            HStack(spacing: 5) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { letter in
                    Text(letter)
                        .font(FlowFont.caption(10))
                        .foregroundStyle(Theme.labelTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Grid rows.
            let cells: [Date?] = Array(repeating: nil, count: normalizedBlanks) + days
            let rows = stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<min($0 + 7, cells.count)]) }

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 5) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, day in
                        if let day {
                            heatmapCell(for: day)
                        } else {
                            Color.clear.frame(height: 26)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func heatmapCell(for day: Date) -> some View {
        let ratio = heatmap[day] ?? 0
        let isToday = Calendar.current.isDateInToday(day)
        let isFuture = day > Date()
        let dayNumber = Calendar.current.component(.day, from: day)

        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(cellColor(ratio: ratio, isFuture: isFuture))

            if isFuture {
                Text("\(dayNumber)")
                    .font(FlowFont.caption(10))
                    .foregroundStyle(Theme.labelTertiary)
            } else {
                Text("\(dayNumber)")
                    .font(FlowFont.caption(10))
                    .fontWeight(.semibold)
                    .foregroundStyle(ratio >= 0.8 ? .white : Theme.labelSecondary)
            }

            if isToday {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Theme.azure, lineWidth: 2)
            }
        }
        .frame(height: 26)
        .frame(maxWidth: .infinity)
    }

    private func cellColor(ratio: Double, isFuture: Bool) -> Color {
        if isFuture { return Theme.labelTertiary.opacity(0.10) }
        switch ratio {
        case ..<0.01: return Theme.azure.opacity(0.06)
        case ..<0.8: return Theme.indigo.opacity(0.35)
        case ..<1.0: return Theme.aqua.opacity(0.75)
        default: return Theme.aqua
        }
    }
}
