import Foundation
import UserNotifications

/// Schedules local "nudge" notifications between active hours,
/// respecting bedtime mode and the chosen interval.
final class NotificationScheduler: ObservableObject {

    static let shared = NotificationScheduler()

    /// Identifier prefix so we can cancel only our reminders.
    private static let idPrefix = "hydroflow.reminder."

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permissions

    /// Request notification permission; updates `authorizationStatus`.
    @MainActor
    func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        authorizationStatus = granted ? .authorized : .denied
        return granted
    }

    /// Read the current authorization state (called at launch).
    @MainActor
    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Scheduling

    /// Plans the reminder times from settings. Exposed for unit testing:
    /// returns hour/minute pairs covering the active window at the chosen interval.
    static func plannedReminderTimes(settings: ReminderSettings) -> [(hour: Int, minute: Int)] {
        guard settings.remindersEnabled, !settings.bedtimeMode else { return [] }

        var times: [(hour: Int, minute: Int)] = []
        let intervalHours = settings.interval.rawValue

        var slot: Double = 0
        while true {
            let totalMinutes = Int((settings.activeStartHour * 60 + slot * 60).rounded())
            let hour = totalMinutes / 60
            guard hour < settings.activeEndHour else { break }
            times.append((hour: hour, minute: totalMinutes % 60))
            slot += intervalHours
        }
        return times
    }

    /// Rebuild the full reminder schedule from settings.
    /// Call after any settings change, app launch, or permission grant.
    func reschedule(settings: ReminderSettings) {
        center.removeAllPendingNotificationRequests()

        guard settings.remindersEnabled, !settings.bedtimeMode else { return }

        for (index, time) in Self.plannedReminderTimes(settings: settings).enumerated() {
            var comps = DateComponents()
            comps.hour = time.hour
            comps.minute = time.minute

            let content = UNMutableNotificationContent()
            content.title = "Time to drink water 💧"
            content.body = Self.messages[index % Self.messages.count]
            content.sound = .default
            content.categoryIdentifier = "REMINDER"

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(Self.idPrefix)\(time.hour)-\(time.minute)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    /// Cancel all HydroFlow reminders.
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Messages

    private static let messages = [
        "Keep the flow going — a glass of water keeps your energy steady.",
        "Your brain is 73% water. Refuel it with a quick sip!",
        "Hydration check! Small sips add up to big wins.",
        "A hydrated body is a happy body. Grab your bottle 🚰",
        "Halfway there? Every glass brings your streak alive.",
        "Quick reset: 8 oz of water boosts focus in minutes.",
        "Evening wind-down — water now means better sleep tonight.",
        "Tiny habit, huge impact. One sip at a time 💙"
    ]
}
