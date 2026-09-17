import Foundation
import WidgetKit

/// Shared App Group identifier used by the app and the Home Screen widget.
/// Sideloaded builds fall back to a plain file when the group is unavailable.
enum WidgetConstants {
    static let appGroupID = "group.com.hydroflow.app"
    static let snapshotFile = "widget_snapshot.json"

    /// The App Group container URL, or Documents when the group isn't
    /// provisioned (unsigned builds still render via the shared JSON).
    static var containerURL: URL {
        if let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return group
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs
    }

    static var snapshotURL: URL {
        containerURL.appendingPathComponent(snapshotFile)
    }
}

/// The compact data blob the Home Screen widget renders. Written by the app
/// on every log/goal change, read by the widget extension's timeline provider.
struct WidgetSnapshot: Codable, Equatable {
    /// Hydration credit logged today, in milliliters.
    var currentML: Double
    /// Today's goal in milliliters (already includes weather bonus).
    var goalML: Double
    /// User's display unit ("ml" / "oz") for label formatting.
    var unitSymbol: String
    /// Current streak in days.
    var streak: Int
    /// Percentage of the day elapsed (for the "day pace" hint).
    var updated: Date

    /// 0...1 fill fraction for the bottle.
    var progress: Double {
        guard goalML > 0 else { return 0 }
        return min(currentML / goalML, 1)
    }

    /// Volume formatted in the display unit.
    func displayText(_ symbol: String? = nil) -> String {
        let sym = symbol ?? unitSymbol
        if sym == "oz" {
            return "\(Int((currentML / VolumeUnit.mlPerOz).rounded())) oz"
        }
        return "\(Int(currentML.rounded())) ml"
    }

    func goalText() -> String {
        if unitSymbol == "oz" {
            return "\(Int((goalML / VolumeUnit.mlPerOz).rounded())) oz"
        }
        return "\(Int(goalML.rounded())) ml"
    }
}

/// App-side publisher: encodes the snapshot into the App Group container and
/// asks WidgetKit to refresh the widget timelines.
enum WidgetPublisher {
    /// Write the latest state and reload widget timelines.
    /// Called after every log/delete/goal change.
    static func publish(store: HydrationStore) {
        publishSnapshot(
            currentML: store.todayTotalML,
            goalML: store.dailyGoalML,
            unitSymbol: store.profile.unit.symbol,
            streak: store.currentStreak
        )
    }

    /// Value-level entry point (used by the store's save path).
    static func publishSnapshot(currentML: Double, goalML: Double, unitSymbol: String, streak: Int) {
        let snapshot = WidgetSnapshot(
            currentML: currentML,
            goalML: goalML,
            unitSymbol: unitSymbol,
            streak: streak,
            updated: Date()
        )
        write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Encode to the App Group container (atomic; best-effort).
    static func write(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: WidgetConstants.snapshotURL, options: .atomic)
    }

    /// Widget-side loader: read the latest snapshot from the shared container.
    static func read() -> WidgetSnapshot? {
        guard let data = try? Data(contentsOf: WidgetConstants.snapshotURL) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
