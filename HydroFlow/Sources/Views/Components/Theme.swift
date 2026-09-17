import SwiftUI

/// HydroFlow design system — colors.
///
/// Translates the "HydroFlow" design language (see `stitch_ui/.../hydroflow/DESIGN.md`)
/// into semantic color roles. The palette is a hybrid of iOS system blues and the
/// aquatic azure→aqua gradient used for primary actions and liquid fills.
enum Theme {

    // MARK: - Core palette

    /// iOS Azure Blue — dominant interactive tone.
    static let azure = Color(red: 0.00, green: 0.48, blue: 1.00)          // #007AFF

    /// Refreshing Aqua Cyan — micro-achievements, completion badges.
    static let aqua = Color(red: 0.00, green: 0.78, blue: 0.75)           // #00C7BE

    /// Deep Indigo — secondary charts, evening tags, gradient stops.
    static let indigo = Color(red: 0.35, green: 0.34, blue: 0.84)         // #5856D6

    /// Brand primary used across mockup chrome (deeper azure, #0058BC).
    static let brandPrimary = Color(red: 0.00, green: 0.35, blue: 0.74)

    // MARK: - Functional canvas

    /// iOS grouped background canvas.
    static let canvas = Color(UIColor.systemGroupedBackground)            // #F2F2F7

    /// Elevated card surface (light mode white).
    static let card = Color(UIColor.secondarySystemGroupedBackground)

    /// Hairline dividers inside grouped lists.
    static let hairline = Color(UIColor.separator)

    // MARK: - Text hierarchy

    static let labelPrimary = Color(UIColor.label)
    static let labelSecondary = Color(UIColor.secondaryLabel)
    static let labelTertiary = Color(UIColor.tertiaryLabel)

    // MARK: - Semantic

    static let success = Color(UIColor.systemGreen)
    static let destructive = Color(UIColor.systemRed)
    static let warning = Color(UIColor.systemOrange)

    /// Icon-tile backgrounds (soft tinted squircles behind SF Symbols).
    static func tile(_ color: Color) -> Color { color.opacity(0.14) }

    // MARK: - Gradients

    /// Signature azure→aqua gradient used by primary capsule buttons and ring strokes.
    static let flowGradient = LinearGradient(
        colors: [azure, aqua],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Vertical liquid gradient for the reservoir orb (sky → ocean depth).
    static let liquidGradient = LinearGradient(
        colors: [
            Color(red: 0.22, green: 0.74, blue: 0.97),   // #38BDF8
            Color(red: 0.01, green: 0.52, blue: 0.78),   // #0284C7
            Color(red: 0.11, green: 0.31, blue: 0.85)    // #1D4ED8
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Soft ambient glow used behind hero cards.
    static let ambientGradient = LinearGradient(
        colors: [azure.opacity(0.10), aqua.opacity(0.10)],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
    )
}

/// Typography tokens mapped from DESIGN.md (Manrope metrics → rounded design).
/// Uses the system rounded face for the friendly, geometric HydroFlow feel.
enum FlowFont {
    static func display(_ size: CGFloat = 44) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func headlineLarge(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func headline(_ size: CGFloat = 22) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func headlineSmall(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func bodyBold(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func caption(_ size: CGFloat = 11) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    static func subhead(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    static func stat(_ size: CGFloat = 32) -> Font { .system(size: size, weight: .bold, design: .rounded) }
}

// MARK: - Shared layout constants

extension CGFloat {
    /// Outer screen gutter from the design system.
    static let margin: CGFloat = 16
    /// Standard card corner radius (continuous squircle look).
    static let cardRadius: CGFloat = 20
    /// Small element radius.
    static let chipRadius: CGFloat = 12
}
