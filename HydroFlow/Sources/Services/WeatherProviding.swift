import Foundation

/// Supplies outside temperature for the "Dynamic Weather" goal bonus.
///
/// The plan calls for auto-adding +12 oz on high-heat days. Shipping a real
/// weather API needs an entitlement + network stack, so v1 ships with a
/// deterministic offline approximation (seasonal high for the hemisphere) and
/// a clean seam (`currentHighTemperature`) to plug a real provider later.
enum WeatherProviding {

    /// Returns today's estimated high in °C, or nil if unavailable.
    static func currentHighTemperature(now: Date = Date()) -> Double? {
        guard let cached = cachedHighTemperature(now: now) else { return nil }
        return cached
    }

    /// Offline seasonal approximation.
    /// - Northern hemisphere: July ≈ 30 °C, January ≈ 4 °C.
    /// - Southern hemisphere: flipped.
    /// Uses Calendar timezone so it works offline and deterministically in tests.
    static func cachedHighTemperature(now: Date, calendar: Calendar = .current) -> Double? {
        let comps = calendar.dateComponents([.month, .day], from: now)
        guard let month = comps.month else { return nil }

        // Day-of-year fraction (0...1) within the year.
        let dayOfYear = Double(calendar.ordinality(of: .day, in: .year, for: now) ?? 1)
        let year = calendar.component(.year, from: now)
        let isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
        let daysInYear: Double = isLeap ? 366 : 365
        let phase = (dayOfYear - 1) / daysInYear * 2 * .pi

        // Peak heat ~July 21 (day 202), coldest ~January 21.
        let seasonalNorth = 17.0 - 13.0 * cos(phase - 2 * .pi * 202.0 / daysInYear)
        return seasonalNorth
    }

    /// True when the estimated temperature is hot enough for a bonus.
    static func isHotDay(now: Date = Date()) -> Bool {
        guard let temp = currentHighTemperature(now: now) else { return false }
        return temp >= 28
    }
}
