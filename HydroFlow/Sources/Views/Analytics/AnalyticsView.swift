import SwiftUI

/// "Hydration Insights": selectable Week / Month / Year / Custom ranges with
/// range-aware summary stats, bar charts, day detail timeline, and a monthly
/// consistency heat-map.
struct AnalyticsView: View {
    @EnvironmentObject var store: HydrationStore

    enum RangeMode: String, CaseIterable, Identifiable {
        case week, month, year, custom
        var id: String { rawValue }

        var label: String {
            switch self {
            case .week: "Week"
            case .month: "Month"
            case .year: "Year"
            case .custom: "Custom"
            }
        }
    }

    @State private var mode: RangeMode = .week
    @State private var customStart: Date = Calendar.current.date(byAdding: .day, value: -13, to: Date()) ?? Date()
    @State private var customEnd: Date = Date()
    @State private var showCustomPicker = false
    @State private var selectedDay: Date?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                rangePicker
                summaryCard
                chartCard
                if mode == .week {
                    dayDetailCard
                    heatmapCard
                }
            }
            .padding(.horizontal, .margin)
            .padding(.top, 8)
            .padding(.bottom, 110)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .background(Theme.canvas)
        .navigationTitle("Hydration Insights")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCustomPicker) { customRangeSheet }
    }

    private var unit: VolumeUnit { store.profile.unit }

    // MARK: - Range resolution

    /// The active date range (inclusive day bounds) for the current mode.
    private var activeRange: (start: Date, end: Date) {
        let cal = Calendar.current
        switch mode {
        case .week:
            let days = StatsEngine.weekDays(reference: Date())
            return (days.first ?? Date(), days.last ?? Date())
        case .month:
            let interval = cal.dateInterval(of: .month, for: Date())
            return (interval?.start ?? Date(), interval?.end ?? Date())
        case .year:
            let interval = cal.dateInterval(of: .year, for: Date())
            return (interval?.start ?? Date(), interval?.end ?? Date())
        case .custom:
            return (cal.startOfDay(for: customStart),
                    cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: customEnd)) ?? Date())
        }
    }

    /// Daily totals within the active range.
    private var rangeDailyTotals: [(day: Date, value: Double)] {
        let cal = Calendar.current
        let (start, end) = activeRange
        var days: [Date] = []
        var cursor = cal.startOfDay(for: start)
        let limit = min(end, Date())
        while cursor < limit, days.count < 400 {
            days.append(cursor)
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return days.map { ($0, StatsEngine.totalML(on: $0, from: store.entries)) }
    }

    // MARK: - Header + range picker

    private var header: some View {
        HStack {
            Spacer()
            Text(rangeText)
                .font(FlowFont.caption())
                .foregroundStyle(Theme.labelTertiary)
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
    }

    private var rangePicker: some View {
        HStack(spacing: 0) {
            ForEach(RangeMode.allCases) { m in
                Button {
                    Feedback.tick(enabled: store.reminderSettings.hapticsEnabled)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { mode = m }
                    if m == .custom { showCustomPicker = true }
                } label: {
                    Text(m.label)
                        .font(FlowFont.bodyBold(13))
                        .fontWeight(mode == m ? .bold : .medium)
                        .foregroundStyle(mode == m ? .white : Theme.labelSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(mode == m ? AnyShapeStyle(Theme.azure) : AnyShapeStyle(Color.clear))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.azure.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.azure.opacity(0.12), lineWidth: 0.5))
    }

    private var rangeText: String {
        let fmt = Self.rangeFormatter
        switch mode {
        case .week:
            let days = StatsEngine.weekDays(reference: Date())
            guard days.count == 7 else { return "" }
            return "\(fmt.string(from: days[0])) – \(fmt.string(from: days[6]))"
        case .month:
            return Self.monthFormatter.string(from: Date())
        case .year:
            return String(Calendar.current.component(.year, from: Date()))
        case .custom:
            return "\(fmt.string(from: customStart)) – \(fmt.string(from: customEnd))"
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        let totals = rangeDailyTotals
        let daysWithData = totals.filter { $0.value > 0 }
        let avg = daysWithData.isEmpty ? 0 : daysWithData.map(\.value).reduce(0, +) / Double(daysWithData.count)
        let daysMet = totals.filter { $0.value >= store.dailyGoalML }.count

        return FlowCard {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(mode.label.uppercased()) METRIC")
                        .font(FlowFont.caption(10))
                        .fontWeight(.bold)
                        .tracking(0.6)
                        .foregroundStyle(Theme.brandPrimary)
                    Text("\(daysMet) / \(max(totals.count, 1)) Days Goal Met")
                        .font(FlowFont.headline())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: 8) {
                        Text("Daily Avg:")
                            .font(FlowFont.subhead())
                            .foregroundStyle(Theme.labelSecondary)
                        Text("\(Int(unit.value(fromML: avg).rounded())) \(unit.symbol)")
                            .font(FlowFont.bodyBold())
                            .foregroundStyle(Theme.brandPrimary)
                        if let change = periodOverPeriodChange {
                            Text(String(format: "%+.0f%% vs prev", change))
                                .font(FlowFont.caption())
                                .fontWeight(.bold)
                                .foregroundStyle(change >= 0 ? Theme.success : Theme.destructive)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(change >= 0 ? Theme.success.opacity(0.12) : Theme.destructive.opacity(0.10)))
                        }
                    }
                }
                Spacer()

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

    /// Average change vs the immediately preceding equal-length window.
    private var periodOverPeriodChange: Double? {
        let cal = Calendar.current
        let (start, _) = activeRange
        let length = rangeDailyTotals.count
        guard length > 0 else { return nil }

        var prevDays: [Date] = []
        if let s = cal.date(byAdding: .day, value: -length, to: cal.startOfDay(for: start)) {
            var cursor = s
            for _ in 0..<length {
                prevDays.append(cursor)
                cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor
            }
        }
        let prevTotals = prevDays.map { StatsEngine.totalML(on: $0, from: store.entries) }.filter { $0 > 0 }
        let curTotals = rangeDailyTotals.map(\.value).filter { $0 > 0 }
        guard !prevTotals.isEmpty, !curTotals.isEmpty else { return nil }
        let prevAvg = prevTotals.reduce(0, +) / Double(prevTotals.count)
        let curAvg = curTotals.reduce(0, +) / Double(curTotals.count)
        guard prevAvg > 0 else { return nil }
        return (curAvg - prevAvg) / prevAvg * 100
    }

    // MARK: - Chart

    private var chartCard: some View {
        FlowCard {
            VStack(spacing: 14) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bar.chart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.azure)
                        Text("\(mode.label) Intake Trend")
                            .font(FlowFont.headlineSmall())
                    }
                    Spacer()
                    Text("Target: \(Int(unit.value(fromML: store.dailyGoalML).rounded())) \(unit.symbol)")
                        .font(FlowFont.caption())
                        .foregroundStyle(Theme.labelTertiary)
                }

                RangeBarChart(
                    totals: rangeDailyTotals,
                    goalML: store.dailyGoalML,
                    unit: unit,
                    labelStyle: labelStyle
                )
            }
        }
    }

    /// How x-axis labels render for the current range size.
    private var labelStyle: RangeBarChart.LabelStyle {
        switch mode {
        case .week: .letters
        case .month: .dayNumbers
        case .year: .months
        case .custom: rangeDailyTotals.count <= 14 ? .letters : .dayNumbers
        }
    }

    // MARK: - Custom range sheet

    private var customRangeSheet: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Custom Range")
                    .font(FlowFont.headline())
                    .padding(.top, 20)

                HStack(spacing: 16) {
                    datePicker("From", selection: $customStart)
                    datePicker("To", selection: $customEnd)
                }

                HStack(spacing: 8) {
                    ForEach([(7, "Last 7 days"), (14, "Last 14 days"), (30, "Last 30 days"), (90, "Last 90 days")],
                            id: \.1) { back, label in
                        Button {
                            let cal = Calendar.current
                            customEnd = Date()
                            customStart = cal.date(byAdding: .day, value: -back, to: Date()) ?? Date()
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

                Spacer()
                Button {
                    if customStart > customEnd { swap(&customStart, &customEnd) }
                    mode = .custom
                    showCustomPicker = false
                } label: {
                    Text("Apply Range")
                        .font(FlowFont.headlineSmall())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(Theme.flowGradient))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
            .presentationDetents([.height(360)])
            .background(Theme.card)
            .navigationTitle("Custom Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func datePicker(_ title: String, selection: Binding<Date>) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(FlowFont.caption())
                .foregroundStyle(Theme.labelSecondary)
            DatePicker("", selection: selection, displayedComponents: .date)
                .labelsHidden()
        }
    }

    // MARK: - Day detail (weekly mode)

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
                            .font(FlowFont.headlineSmall())
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(Int(unit.value(fromML: total).rounded())) / \(Int(unit.value(fromML: store.dailyGoalML).rounded())) \(unit.symbol)")
                            .font(FlowFont.bodyBold())
                            .foregroundStyle(Theme.brandPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(percentText(total))
                            .font(FlowFont.caption())
                            .fontWeight(.bold)
                            .foregroundStyle(total >= store.dailyGoalML ? Theme.success : Theme.warning)
                    }
                }

                if dayEntries.isEmpty {
                    Text("No entries for this day.")
                        .font(FlowFont.subhead())
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

    // MARK: - Heatmap (weekly mode)

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
                            .font(FlowFont.headlineSmall())
                    }
                    Spacer()
                    Text("\(metDays) / \(heatmap.count) days")
                        .font(FlowFont.caption())
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.brandPrimary)
                }

                MonthHeatmapGrid(heatmap: heatmap, unit: unit)
                    .padding(.top, 2)

                HStack(spacing: 14) {
                    Spacer()
                    legendSwatch(color: Theme.indigo.opacity(0.35), label: "<80%")
                    legendSwatch(color: Theme.aqua.opacity(0.75), label: "80–99%")
                    legendSwatch(color: Theme.aqua, label: "100%+ Met")
                }
                .font(FlowFont.caption())
                .foregroundStyle(Theme.labelTertiary)
            }
        }
    }

    // MARK: - Helpers

    private var lastDayWithData: Date {
        let withData = store.entries.map { Calendar.current.startOfDay(for: $0.date) }.max()
        return withData ?? Date()
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

// MARK: - Range bar chart

/// Bar chart for arbitrary day ranges: bars auto-thin, labels adapt
/// (weekday letters → day numbers → month names), goal line on top.
struct RangeBarChart: View {
    enum LabelStyle { case letters, dayNumbers, months }

    let totals: [(day: Date, value: Double)]
    let goalML: Double
    let unit: VolumeUnit
    let labelStyle: LabelStyle

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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: barSpacing) {
                    ForEach(Array(totals.enumerated()), id: \.element.day) { index, item in
                        DayBar(
                            date: item.day,
                            totalML: item.value,
                            goalML: goalML,
                            unit: unit,
                            isToday: Calendar.current.isDateInToday(item.day),
                            isFuture: item.day > Date(),
                            label: axisLabel(for: item.day),
                            showValue: totals.count <= 14,
                            barWidth: barWidth,
                            appearanceDelay: Double(index) * 0.04
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
            .frame(height: 150)
        }
    }

    private var barWidth: CGFloat {
        switch totals.count {
        case ..<9: return 26
        case 9..<16: return 18
        case 16..<32: return 12
        default: return 7
        }
    }

    private var barSpacing: CGFloat {
        switch totals.count {
        case ..<9: return 8
        case 9..<16: return 6
        case 16..<32: return 4
        default: return 2
        }
    }

    private func axisLabel(for day: Date) -> String {
        let fmt = DateFormatter()
        switch labelStyle {
        case .letters:
            fmt.dateFormat = "EEEEE"
            return fmt.string(from: day)
        case .dayNumbers:
            fmt.dateFormat = "d"
            return fmt.string(from: day)
        case .months:
            fmt.dateFormat = "MMM"
            return fmt.string(from: day)
        }
    }
}

/// One bar in the range chart.
struct DayBar: View {
    let date: Date
    let totalML: Double
    let goalML: Double
    let unit: VolumeUnit
    let isToday: Bool
    let isFuture: Bool
    let label: String
    let showValue: Bool
    let barWidth: CGFloat
    var appearanceDelay: Double = 0

    @State private var appeared = false

    private var maxHeight: CGFloat { 112 }

    private var fillFraction: CGFloat {
        guard goalML > 0 else { return 0 }
        return min(CGFloat(totalML / goalML), 1)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(showValue && !isFuture ? "\(Int(unit.value(fromML: totalML).rounded()))" : " ")
                .font(.system(size: 9, weight: isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(isToday ? Theme.brandPrimary : Theme.labelSecondary)
                .frame(height: 12)

            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Theme.azure.opacity(0.08))
                    .frame(width: barWidth, height: maxHeight)

                if isFuture {
                    Capsule()
                        .fill(Theme.labelTertiary.opacity(0.15))
                        .frame(width: barWidth, height: 24)
                        .overlay(Capsule().strokeBorder(style: StrokeStyle(lineWidth: 0.8, dash: [3])).foregroundStyle(Theme.labelTertiary))
                } else if totalML > 0 {
                    Capsule()
                        .fill(barGradient)
                        .frame(width: barWidth, height: max(6, fillFraction * maxHeight))
                        .shadow(color: isToday ? Theme.azure.opacity(0.45) : .clear, radius: 8)
                        .scaleEffect(y: appeared ? 1 : 0, anchor: .bottom)
                } else {
                    Capsule()
                        .fill(Theme.azure.opacity(0.12))
                        .frame(width: barWidth, height: 4)
                }
            }
            .frame(height: maxHeight)

            Text(label)
                .font(FlowFont.caption(9.5))
                .fontWeight(isToday ? .bold : .medium)
                .foregroundStyle(isToday ? Theme.brandPrimary : Theme.labelSecondary)
                .frame(width: max(barWidth, 16))
        }
        .opacity(isFuture ? 0.55 : 1)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(appearanceDelay)) {
                appeared = true
            }
        }
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
                    .font(FlowFont.subhead())
                    .fontWeight(.semibold)
                Text("\(entry.date, formatter: Self.timeFormatter) • \(entry.containerName ?? entry.beverage.displayName)")
                    .font(FlowFont.caption())
                    .foregroundStyle(Theme.labelSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Text("+\(Int(unit.value(fromML: entry.volumeML).rounded())) \(unit.symbol)")
                .font(FlowFont.bodyBold())
                .fixedSize()
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
            HStack(spacing: 5) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { letter in
                    Text(letter)
                        .font(FlowFont.caption(10))
                        .foregroundStyle(Theme.labelTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

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

            Text("\(dayNumber)")
                .font(FlowFont.caption(10))
                .fontWeight(isFuture ? .regular : .semibold)
                .foregroundStyle(isFuture ? Theme.labelTertiary : (ratio >= 0.8 ? Color.white : Theme.labelSecondary))

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
