import SwiftUI

/// A type token: a size, a weight, the Dynamic Type ramp it grows along, and the
/// tracking and leading that belong with it.
///
/// Tracking is carried here rather than applied ad hoc, because the display
/// sizes only read correctly with negative tracking and the mono-ish labels
/// only read correctly with positive tracking. Splitting them apart is how a
/// type system drifts.
///
/// `ramp` is the system text style whose growth curve this token follows. It is
/// not the token's size — a 56pt display and a 12pt label both scale, but a
/// display that grew as fast as a caption would run off the screen at the first
/// step. Apple publishes a different curve per style; picking the nearest one is
/// how a custom scale inherits that tuning instead of guessing at it.
struct TextStyle {
    var size: CGFloat
    var weight: Font.Weight
    var ramp: Font.TextStyle
    var tracking: CGFloat = 0
    var lineSpacing: CGFloat = 0
}

/// SF Pro throughout, per the handoff. No bundled font files and no licence
/// surface.
///
/// **On Dynamic Type.** These are authored point sizes rather than the system
/// styles, because the handoff's scale (56 / 32 / 24 / 18 / 16 / 14 / 12 / 11)
/// is not Apple's (34 / 28 / 22 / 17 / 16 / 15 / 13 / 11) and the display sizes
/// are load-bearing for the layout. Authored sizes do **not** scale on their
/// own — `Font.system(size:)` is a fixed font, which is the trap this file used
/// to be in — so every token is put through `ScaledMetric` at the point of use.
/// The result keeps the designed size at the default text setting and grows
/// along the right curve from there.
enum TypeScale {

    /// 56/64, -0.02em. Page titles on iPad only.
    static let displayLG = TextStyle(
        size: 56,
        weight: .bold,
        ramp: .largeTitle,
        tracking: -1.12,
        lineSpacing: 4
    )

    /// 32/40, -0.02em. Page titles in compact width; board titles.
    static let displayMD = TextStyle(
        size: 32,
        weight: .bold,
        ramp: .title,
        tracking: -0.64,
        lineSpacing: 4
    )

    /// 24/32. Section headings.
    static let headline = TextStyle(
        size: 24,
        weight: .semibold,
        ramp: .title2,
        tracking: -0.24,
        lineSpacing: 4
    )

    /// 18/28. Lead paragraphs and note bodies.
    static let bodyLG = TextStyle(
        size: 18,
        weight: .regular,
        ramp: .body,
        lineSpacing: 6
    )

    /// 16/24. Default body.
    static let bodyMD = TextStyle(
        size: 16,
        weight: .regular,
        ramp: .body,
        lineSpacing: 4
    )

    /// 14/20. Dense supporting copy.
    static let bodySM = TextStyle(
        size: 14,
        weight: .regular,
        ramp: .subheadline,
        lineSpacing: 2
    )

    /// 12/16, +0.1em, uppercase. Timestamps, presence, metadata.
    static let labelCaps = TextStyle(
        size: 12,
        weight: .medium,
        ramp: .caption,
        tracking: 1.2
    )

    /// 11/14, +0.09em, uppercase. Nav bar labels.
    ///
    /// 11pt is the platform's legibility floor, and this token sits on it. It
    /// was 10pt — uppercase, letterspaced, bold and below the floor, on the
    /// control the user touches most.
    static let labelTiny = TextStyle(
        size: 11,
        weight: .bold,
        ramp: .caption2,
        tracking: 1.0
    )

    /// 14/18, bold. Sticker faces.
    static let sticker = TextStyle(
        size: 14,
        weight: .bold,
        ramp: .subheadline,
        tracking: 0.7
    )
}

/// Applies a `TextStyle` at the reader's text size.
///
/// `ScaledMetric` is what makes this work: it runs the authored size through
/// `UIFontMetrics` for the token's ramp, so the number it hands back already
/// carries Apple's curve for that style. Tracking and leading are then scaled by
/// the same ratio — letterspacing is optical and belongs to the size it was
/// drawn for, so a fixed 1.2pt of tracking that reads as +0.1em at 12pt would
/// read as +0.04em at 28pt and the label would lose its character.
struct ScaledTextStyle: ViewModifier {

    private let style: TextStyle
    @ScaledMetric private var size: CGFloat

    init(_ style: TextStyle) {
        self.style = style
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.ramp)
    }

    func body(content: Content) -> some View {
        let ratio = size / style.size

        return content
            .font(.system(size: size, weight: style.weight))
            .tracking(style.tracking * ratio)
            .lineSpacing(style.lineSpacing * ratio)
    }
}

extension View {
    func textStyle(_ style: TextStyle) -> some View {
        modifier(ScaledTextStyle(style))
    }

    /// A symbol that grows on the same ramp as the label beside it.
    ///
    /// SF Symbols take their size from the font, so a fixed `.system(size:)` on
    /// an icon leaves it stranded at its original size while the text next to it
    /// scales — the pairing drifts apart exactly when the reader most needs it to
    /// hold together. Icons keep their own size and weight, which are optically
    /// matched to the label rather than equal to it, and inherit only the ramp.
    func symbolStyle(_ style: TextStyle, size: CGFloat, weight: Font.Weight) -> some View {
        modifier(ScaledTextStyle(TextStyle(size: size, weight: weight, ramp: style.ramp)))
    }
}

extension View {
    /// Caps how far a subtree's type may grow.
    ///
    /// For the two places where text is not the thing being read: objects on the
    /// canvas, whose size the user already controls directly by pinching, and
    /// the dock, which is a fixed-width capsule. Both stop at the largest
    /// non-accessibility step — they still grow by about a third for anyone who
    /// has turned text up, but they cannot reach the accessibility sizes, where
    /// a 310% label would rearrange a board or break the dock.
    ///
    /// This is a ceiling, never a freeze. Every other surface in the app scales
    /// the whole way.
    func fixedLayoutTypeCeiling() -> some View {
        dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}
