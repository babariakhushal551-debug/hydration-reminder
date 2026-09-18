import SwiftUI

/// HydroFlow design system — colors.
///
/// Directly transcribed from the stitch design tokens
/// (`stitch_ui/stitch_hydration_tracker_app_ui/hydroflow/DESIGN.md`):
/// surface `#faf9fe`, white cards, outline-variant `#c1c6d7`,
/// primary `#0058bc`, interactive `#0070eb`, gradient `#0070eb → #39dcd2`.
/// Dark variants keep the same roles (mirrors the web preview's dark theme).
enum Theme {

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    // MARK: - Core palette

    /// Interactive azure (stitch `primary-container` #0070EB).
    static let azure = dynamic(light: UIColor(red: 0.00, green: 0.44, blue: 0.92, alpha: 1),
                               dark: UIColor(red: 0.25, green: 0.61, blue: 1.00, alpha: 1))

    /// Refreshing aqua (stitch secondary family).
    static let aqua = dynamic(light: UIColor(red: 0.00, green: 0.78, blue: 0.75, alpha: 1),
                              dark: UIColor(red: 0.22, green: 0.86, blue: 0.82, alpha: 1))

    /// Deep indigo (stitch tertiary #4C4ACA / #6664E4).
    static let indigo = dynamic(light: UIColor(red: 0.30, green: 0.29, blue: 0.79, alpha: 1),
                                dark: UIColor(red: 0.40, green: 0.39, blue: 0.89, alpha: 1))

    /// Brand primary for text/badges (stitch `primary` #0058BC; lighter on dark).
    static let brandPrimary = dynamic(light: UIColor(red: 0.00, green: 0.35, blue: 0.74, alpha: 1),
                                      dark: UIColor(red: 0.30, green: 0.64, blue: 1.00, alpha: 1))

    // MARK: - Functional canvas

    /// Stitch `surface` #FAF9FE light / near-black canvas dark.
    static let canvas = dynamic(light: UIColor(red: 0.980, green: 0.976, blue: 0.996, alpha: 1),
                                dark: UIColor(red: 0.020, green: 0.020, blue: 0.035, alpha: 1))

    /// Stitch `surface-container-lowest` #FFFFFF light / elevated dark surface.
    static let card = dynamic(light: .white,
                              dark: UIColor(red: 0.071, green: 0.071, blue: 0.094, alpha: 1))

    /// Stitch `outline-variant` #C1C6D7 hairlines (inverted on dark).
    static let hairline = dynamic(light: UIColor(red: 0.757, green: 0.776, blue: 0.843, alpha: 0.6),
                                  dark: UIColor(white: 1.0, alpha: 0.10))

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

    /// Stitch CTA gradient: #0070EB → #39DCD2 at 135°.
    static let flowGradient = LinearGradient(
        colors: [Color(red: 0.00, green: 0.44, blue: 0.92),
                 Color(red: 0.22, green: 0.86, blue: 0.82)],
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

/// Typography tokens mapped from DESIGN.md (Manrope metrics → SF Pro).
/// Manrope's geometry is closest to plain SF Pro — the previous `.rounded`
/// design made every surface look toy-like and drifted from the mockups.
enum FlowFont {
    static func display(_ size: CGFloat = 44) -> Font { .system(size: size, weight: .heavy) }
    static func headlineLarge(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .bold) }
    static func headline(_ size: CGFloat = 22) -> Font { .system(size: size, weight: .semibold) }
    static func headlineSmall(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .semibold) }
    static func body(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .regular) }
    static func bodyBold(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .semibold) }
    static func caption(_ size: CGFloat = 11) -> Font { .system(size: size, weight: .medium) }
    static func subhead(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .medium) }
    static func stat(_ size: CGFloat = 32) -> Font { .system(size: size, weight: .bold) }
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
