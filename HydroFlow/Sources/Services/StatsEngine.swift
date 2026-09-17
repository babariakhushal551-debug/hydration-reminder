import Foundation

/// Lightweight stats engine: streaks, calendar days, weekly/monthly aggregates.
enum StatsEngine {

    /// Calendar day key, e.g. "2026-09-18".
    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// All entries belonging to a specific calendar day.
    static func entries(on date: Date, from entries: [WaterEntry], calendar: Calendar = .current) -> [WaterEntry] {
        entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    /// Total hydration credit for a day, in milliliters.
    static func totalML(on date: Date, from entries: [WaterEntry], calendar: Calendar = .current) -> Double {
        entries(on: date, from: entries, calendar: calendar).reduce(0) { $0 + $1.hydrationML }
    }

    /// Whether a day met its goal (≥ 100%).
    static func isGoalMet(on date: Date, goalML: Double, entries: [WaterEntry], calendar: Calendar = .current) -> Bool {
        totalML(on: date, from: entries, calendar: calendar) >= goalML
    }

    /// Consecutive days (ending today or yesterday) where the goal was met.
    ///
    /// - If today already meets the goal, the streak counts today and walks backward.
    /// - If today hasn't met the goal yet, the streak counts through yesterday
    ///   (the day is still "in progress" and shouldn't break the chain).
    /// - If yesterday also missed, streak is zero.
    static func currentStreak(goalML: Double, entries: [WaterEntry], calendar: Calendar = .current, now: Date = Date()) -> Int {
        var day = calendar.startOfDay(for: now)
        let todayMet = isGoalMet(on: day, goalML: goalML, entries: entries, calendar: calendar)

        if !todayMet {
            // Today still in progress — streak depends on yesterday and before.
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while isGoalMet(on: day, goalML: goalML, entries: entries, calendar: calendar) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    /// Daily totals (ML) for the week containing `reference`, Monday-first, 7 slots.
    /// Values are `nil` for days with no data (rendered as dashed "no data" bars).
    static func weekTotals(reference: Date, entries: [WaterEntry], calendar: Calendar = .current) -> [Date: Double] {
        var result: [Date: Double] = [:]
        for day in weekDays(reference: reference, calendar: calendar) {
            result[day] = totalML(on: day, from: entries, calendar: calendar)
        }
        return result
    }

    /// Monday-first array of 7 day-starts for the week containing `reference`.
    static func weekDays(reference: Date, calendar: Calendar = .current) -> [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: reference) else { return [] }
        var days: [Date] = []
        for offset in 0..<7 {
            if let d = calendar.date(byAdding: .day, value: offset, to: weekInterval.start) {
                days.append(d)
            }
        }
        return days
    }

    /// How many days in the week met the goal.
    static func daysGoalMetInWeek(reference: Date, goalML: Double, entries: [WaterEntry], calendar: Calendar = .current) -> Int {
        weekDays(reference: reference, calendar: calendar).filter {
            isGoalMet(on: $0, goalML: goalML, entries: entries, calendar: calendar)
        }.count
    }

    /// Average daily hydration across the current week (only days with data).
    static func weekAverageML(reference: Date, entries: [WaterEntry], calendar: Calendar = .current) -> Double {
        let totals = weekTotals(reference: reference, entries: entries, calendar: calendar).values.filter { $0 > 0 }
        guard !totals.isEmpty else { return 0 }
        return totals.reduce(0, +) / Double(totals.count)
    }

    /// Percent change vs the previous week (for the "+4% vs lw" badge).
    static func weekOverWeekChange(reference: Date, entries: [WaterEntry], calendar: Calendar = .current) -> Double? {
        let thisWeek = weekAverageML(reference: reference, entries: entries, calendar: calendar)
        guard let lastWeekRef = calendar.date(byAdding: .weekOfYear, value: -1, to: reference) else { return nil }
        let lastWeek = weekAverageML(reference: lastWeekRef, entries: entries, calendar: calendar)
        guard lastWeek > 0 else { return nil }
        return (thisWeek - lastWeek) / lastWeek * 100
    }

    /// Calendar heatmap model for one month.
    /// - Returns day-starts with their goal-completion ratio (0.0 – 1.0+), keyed by day.
    static func monthHeatmap(year: Int, month: Int, goalML: Double, entries: [WaterEntry], calendar: Calendar = .current) -> [Date: Double] {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let first = calendar.date(from: comps),
              let monthInterval = calendar.dateInterval(of: .month, for: first) else { return [:] }

        var result: [Date: Double] = [:]
        var day = monthInterval.start
        while day < monthInterval.end {
            let total = totalML(on: day, from: entries, calendar: calendar)
            result[day] = goalML > 0 ? min(total / goalML, 1.5) : 0
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    /// Percentage of a daily goal completed, 0.0 – 1.0+.
    static func progress(goalML: Double, totalML: Double) -> Double {
        guard goalML > 0 else { return 0 }
        return totalML / goalML
    }
}
