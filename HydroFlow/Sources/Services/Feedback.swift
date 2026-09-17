import UIKit

/// Centralized haptic + sound feedback ("Sounds & Haptics" settings section).
enum Feedback {
    /// Light impact when logging a drink.
    static func sipLogged(enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Success notification when the daily goal is reached.
    static func goalReached(enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Selection tick for steppers, segmented controls, chips.
    static func tick(enabled: Bool) {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
