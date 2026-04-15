import SwiftUI

/// Kit design token system — single source of truth for all colors, typography,
/// spacing, and semantic aliases used throughout the app.
///
/// All views reference KitTheme exclusively — no inline color literals anywhere else.
enum KitTheme {

    // MARK: - Core palette

    /// Burnt-sienna fox orange. #E8632A — CTAs, accents, send button, avatar bg, borders.
    static let orange      = Color(red: 0.910, green: 0.388, blue: 0.165)

    /// Soft peachy orange. #F4956A — user chat bubbles.
    static let lightOrange = Color(red: 0.957, green: 0.584, blue: 0.416)

    /// Warm cream. #FFF3E6 — fox response bubbles, main chat fill.
    static let cream       = Color(red: 1.000, green: 0.953, blue: 0.902)

    /// Panel cream. #FFF8F0 — conversation panel background, section backgrounds.
    static let creamPanel  = Color(red: 1.000, green: 0.973, blue: 0.941)

    /// Input cream. #FFF0E0 — input row tint when focused.
    static let creamInput  = Color(red: 1.000, green: 0.941, blue: 0.878)

    /// Hover cream. #FAF0E8 — hover and pressed states.
    static let creamHover  = Color(red: 0.980, green: 0.941, blue: 0.910)

    /// Dark brown. #2D1A08 — primary text, headings, body copy.
    static let darkBrown   = Color(red: 0.176, green: 0.102, blue: 0.031)

    /// Mid brown. #7A3E12 — secondary text, borders, explanatory copy.
    static let midBrown    = Color(red: 0.478, green: 0.243, blue: 0.071)

    /// Success green. #3A7A3A — ready state, capture confirmation.
    static let success     = Color(red: 0.227, green: 0.478, blue: 0.227)

    // MARK: - Semantic aliases

    /// Standard dividers and card borders — darkBrown at 12% opacity.
    static var border:       Color { darkBrown.opacity(0.12) }

    /// Subtle dividers — darkBrown at 7% opacity.
    static var borderLight:  Color { darkBrown.opacity(0.07) }

    /// Secondary text and disabled states — darkBrown at 48% opacity.
    static var muted:        Color { darkBrown.opacity(0.48) }

    // MARK: - Typography

    /// 13pt regular — message bubbles, body copy, input text.
    static func body() -> Font        { .system(size: 13) }

    /// 13pt semibold — panel labels, section headers.
    static func label() -> Font       { .system(size: 13, weight: .semibold) }

    /// 11pt semibold — uppercase section labels, badges.
    static func micro() -> Font       { .system(size: 11, weight: .semibold) }

    // MARK: - macOS traffic-light colours (decorative)

    static let trafficRed    = Color(red: 1.000, green: 0.373, blue: 0.341) // #FF5F57
    static let trafficYellow = Color(red: 1.000, green: 0.741, blue: 0.180) // #FFBD2E
    static let trafficGreen  = Color(red: 0.157, green: 0.784, blue: 0.251) // #28C840
}
