import SwiftUI

/// A type token: font + the tracking and leading that belong with it.
///
/// Tracking is carried here rather than applied ad hoc, because the display
/// sizes only read correctly with negative tracking and the mono-ish labels
/// only read correctly with positive tracking. Splitting them apart is how a
/// type system drifts.
struct TextStyle {
    var font: Font
    var tracking: CGFloat = 0
    var lineSpacing: CGFloat = 0
}

/// SF Pro throughout, per the handoff. No bundled font files, no licence
/// surface, and it inherits Dynamic Type and optical sizing for free.
enum TypeScale {

    /// 56/64, -0.02em. Page titles on iPad only.
    static let displayLG = TextStyle(
        font: .system(size: 56, weight: .bold),
        tracking: -1.12,
        lineSpacing: 4
    )

    /// 32/40, -0.02em. Page titles in compact width; board titles.
    static let displayMD = TextStyle(
        font: .system(size: 32, weight: .bold),
        tracking: -0.64,
        lineSpacing: 4
    )

    /// 24/32. Section headings.
    static let headline = TextStyle(
        font: .system(size: 24, weight: .semibold),
        tracking: -0.24,
        lineSpacing: 4
    )

    /// 18/28. Lead paragraphs and note bodies.
    static let bodyLG = TextStyle(
        font: .system(size: 18, weight: .regular),
        lineSpacing: 6
    )

    /// 16/24. Default body.
    static let bodyMD = TextStyle(
        font: .system(size: 16, weight: .regular),
        lineSpacing: 4
    )

    /// 14/20. Dense supporting copy.
    static let bodySM = TextStyle(
        font: .system(size: 14, weight: .regular),
        lineSpacing: 2
    )

    /// 12/16, +0.1em, uppercase. Timestamps, presence, metadata.
    static let labelCaps = TextStyle(
        font: .system(size: 12, weight: .medium),
        tracking: 1.2
    )

    /// 10/14, +0.1em, uppercase. Nav bar labels.
    static let labelTiny = TextStyle(
        font: .system(size: 10, weight: .bold),
        tracking: 1.0
    )

    /// 14/18, bold. Sticker faces.
    static let sticker = TextStyle(
        font: .system(size: 14, weight: .bold),
        tracking: 0.7
    )
}

extension View {
    func textStyle(_ style: TextStyle) -> some View {
        self
            .font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
    }
}
