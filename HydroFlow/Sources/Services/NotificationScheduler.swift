import Foundation
import UserNotifications

/// Schedules local "nudge" notifications between active hours,
/// respecting bedtime mode, custom intervals, and the chosen sound.
final class NotificationScheduler: ObservableObject {

    static let shared = NotificationScheduler()

    /// Identifier prefix so we can cancel only our reminders.
    private static let idPrefix = "hydroflow.reminder."

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    /// Foreground presentation delegate.
    ///
    /// BUG FIX (the last missing piece): iOS **never displays banners for local
    /// notifications while the app is in the foreground** unless a
    /// UNUserNotificationCenterDelegate explicitly allows it. Users testing
    /// with the app open saw "no notifications" even though everything was
    /// scheduled correctly. This delegate shows banner + sound + haptic.
    private let foregroundDelegate = ForegroundPresentationDelegate()

    private init() {
        center.delegate = foregroundDelegate
    }

    // MARK: - Permissions

    /// Request notification permission; updates `authorizationStatus`.
    @MainActor
    func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        authorizationStatus = granted ? .authorized : .denied
        return granted
    }

    /// Make sure we have permission to actually deliver notifications.
    ///
    /// BUG FIX: previously nothing in the app ever called `requestAuthorization`,
    /// so iOS never showed the permission prompt and every scheduled request was
    /// silently dropped by the system. This now asks when undetermined and falls
    /// back to provisional (quiet) delivery so time-sensitive nudges still work.
    @MainActor
    @discardableResult
    func ensureAuthorization() async -> Bool {
        await refreshAuthorizationStatus()
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            if await requestAuthorization() { return true }
            // User declined the prompt — try quiet provisional delivery so
            // time-sensitive nudges can still arrive in Notification Center.
            _ = (try? await center.requestAuthorization(options: [.alert, .sound, .badge, .provisional])) ?? false
            await refreshAuthorizationStatus()
            return authorizationStatus == .authorized || authorizationStatus == .provisional
        default:
            // .denied — user must enable in Settings; nothing we can do.
            return false
        }
    }

    /// Read the current authorization state (called at launch).
    @MainActor
    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Scheduling

    /// Plans the reminder times from settings. Exposed for unit testing:
    /// returns hour/minute pairs covering the active window at the chosen
    /// interval. Supports windows that wrap past midnight (e.g. 20:00 → 06:00)
    /// and fully custom minute cadences.
    static func plannedReminderTimes(settings: ReminderSettings) -> [(hour: Int, minute: Int)] {
        guard settings.remindersEnabled, !settings.bedtimeMode else { return [] }

        var times: [(hour: Int, minute: Int)] = []
        let stepMinutes = max(5, settings.effectiveIntervalMinutes)
        let startTotal = settings.activeStartHour * 60
        // Window length in minutes; wraps past midnight when start >= end.
        let windowMinutes = settings.wrapsMidnight
            ? (24 * 60 - startTotal) + settings.activeEndHour * 60
            : settings.activeEndHour * 60 - startTotal

        var offset: Double = 0
        while offset < Double(windowMinutes) {
            let totalMinutes = Int((Double(startTotal) + offset).rounded()) % (24 * 60)
            times.append((hour: totalMinutes / 60, minute: totalMinutes % 60))
            offset += stepMinutes
        }
        return times
    }

    /// Rebuild the full reminder schedule from settings.
    /// Call after any settings change, app launch, or permission grant.
    ///
    /// Deliberately synchronous (call sites include onChange closures) and
    /// hops to an async context internally to resolve permissions first —
    /// a sync function cannot itself `await`.
    @MainActor
    func reschedule(settings: ReminderSettings, soundManager: SoundManager? = nil) {
        center.removeAllPendingNotificationRequests()

        guard settings.remindersEnabled, !settings.bedtimeMode else { return }

        Task { await scheduleAfterPermissionCheck(settings: settings, soundManager: soundManager) }
    }

    /// Async body of `reschedule`: ensures permission, then adds requests.
    @MainActor
    private func scheduleAfterPermissionCheck(settings: ReminderSettings, soundManager: SoundManager?) async {
        // Requests are useless without permission: ask/upgrade first, and if
        // the user has denied, stop scheduling (Settings shows how to fix).
        guard await ensureAuthorization() else { return }

        // Resolve the notification sound up-front (installs system files if needed).
        let sound: UNNotificationSound
        if let soundManager {
            let option = soundManager.option(forID: settings.soundName)
            if let option { _ = soundManager.installForNotifications(option) }
            sound = soundManager.notificationSound(forID: settings.soundName)
        } else {
            sound = .default
        }

        // iOS allows at most 64 pending local notification requests; a dense
        // cadence (e.g. 10-min interval over 24 h = 144 slots) would silently
        // drop everything past the limit — so cap the schedule ourselves.
        let schedule = Self.plannedReminderTimes(settings: settings).prefix(64)

        for (index, time) in schedule.enumerated() {
            var comps = DateComponents()
            comps.hour = time.hour
            comps.minute = time.minute

            let content = UNMutableNotificationContent()
            content.title = "Time to drink water 💧"
            content.body = Self.messages[index % Self.messages.count]
            content.sound = sound
            content.categoryIdentifier = "REMINDER"
            // With 90-min cadence the message list wraps after 8 slots; a
            // unique thread per slot keeps notifications stacking cleanly.
            content.threadIdentifier = "hydroflow-\(time.hour)-\(time.minute)"

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(Self.idPrefix)\(time.hour)-\(time.minute)",
                content: content,
                trigger: trigger
            )
            do {
                try await center.add(request)
            } catch {
                // Non-fatal (e.g. permission raced mid-schedule); the rest of
                // the requests still land.
            }
        }
    }

    /// Cancel all HydroFlow reminders.
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Messages

    /// Foreground banner presentation (see init).
    final class ForegroundPresentationDelegate: NSObject, UNUserNotificationCenterDelegate {
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            completionHandler([.banner, .sound, .badge, .list])
        }

        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            completionHandler()
        }
    }

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
