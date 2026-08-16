import SwiftUI
import UIKit

extension Color {
    /// `Color(hex: 0xC8FF2E)`
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }

    /// A colour that resolves against the current interface style.
    ///
    /// This is how light mode is delivered without touching a single call site:
    /// every token below stays `Palette.something`, and UIKit resolves the right
    /// value at render time. A `@Published` theme colour would instead force a
    /// full re-render of every view on every theme read.
    static func adaptive(light: UInt32, dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1) -> Color {
        Color(
            UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(hex: dark, alpha: darkAlpha)
                    : UIColor(hex: light, alpha: lightAlpha)
            }
        )
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }
}

/// The single source of truth for colour in the app.
///
/// **The world is a gallery wall.** The room is neutral and quiet; the
/// photographs are the only colour in it.
///
/// Every structural surface below is achromatic on purpose. A tinted ground —
/// brown, blue, any cast at all — competes with the prints hung on it, and the
/// prints are the product. Neutral is not the absence of a decision here; it is
/// the decision that lets six photographs of six different days sit on one
/// screen without fighting each other or the room.
///
/// Four rules govern every use of this palette:
///
/// 1. **Gold is a verb, not a surface.** `neon` (the token kept its name; the
///    colour is now a photo-corner gold) only ever marks things that are
///    *active* or *actionable*. It is never a background for passive content,
///    and it is the only warm thing in the chrome.
/// 2. **Flat, not lit.** Surfaces are single flat fills. No gradient stands in
///    for a surface, no blurred colour bloom stands in for depth. Depth comes
///    from the ladder below and from real shadows with a real offset.
/// 3. **Objects don't change colour when you turn the lights on.** Light mode
///    changes the *room* — the wall the memories hang on — not the memories.
///    Paper stays paper, vinyl stays vinyl, photos stay photos. Only the
///    surface ladder and body text adapt, which is why the tactile language
///    survives the theme switch intact rather than becoming a washed-out
///    inversion of itself.
/// 4. **Two accents, and they mean one thing each.** Gold means active. Red
///    means destructive or unread. Nothing else gets a colour.
enum Palette {

    // MARK: Foundation — the surface ladder (adapts)

    /// Level 0. The app background.
    ///
    /// **Why light mode is not white.** Two separate mistakes make a light
    /// theme glare. The first is using `#FFFFFF` for large surfaces at all —
    /// on a display that reaches 1000 nits that is simply a lamp, and every
    /// design system that has thought about it lands on an off-white instead.
    /// The second is subtler and was the real fault here: the background and
    /// the cards sat 2% apart, so the whole screen read as one flat sheet with
    /// no structure, and the eye had nothing to rest against.
    ///
    /// The fix is range. The page is now meaningfully toned, cards are near-
    /// white rather than white, and there is a real step between them — so
    /// cards read as objects lying on a surface, which is what they are.
    static let void = Color.adaptive(light: 0xEDEDEB, dark: 0x0A0A0B)
    /// Level 0.5. The canvas field, so item shadows read against it.
    static let board = Color.adaptive(light: 0xE4E4E1, dark: 0x0F0F11)
    /// Level 1. Cards resting on the wall.
    static let charcoal = Color.adaptive(light: 0xFCFCFB, dark: 0x151517)
    static let surface = Color.adaptive(light: 0xF7F7F5, dark: 0x1A1A1C)
    static let containerLow = Color.adaptive(light: 0xF1F1EE, dark: 0x202023)
    static let container = Color.adaptive(light: 0xE9E9E6, dark: 0x26262A)
    static let containerHigh = Color.adaptive(light: 0xDFDFDB, dark: 0x2F2F33)
    static let containerHighest = Color.adaptive(light: 0xD3D3CE, dark: 0x38383D)

    // MARK: Content (adapts)

    /// Not pure black on light: near-black at full strength on an off-white
    /// ground is its own kind of glare, and 0x17171A still clears AA by miles.
    static let onSurface = Color.adaptive(light: 0x17171A, dark: 0xF4F4F5)
    static let onSurfaceVariant = Color.adaptive(light: 0x56565B, dark: 0xA6A6AD)
    static let outline = Color.adaptive(light: 0x8A8A90, dark: 0x6E6E75)

    // MARK: Physical objects (static — see rule 3)

    /// Level 2. Photo mounts, polaroids, sticky notes.
    static let paper = Color(hex: 0xFAFAFA)
    static let onPaper = Color(hex: 0x101010)
    /// Keylines on vinyl stickers and objects. Always near-black: a sticker's
    /// dark outline is part of the object, not part of the theme.
    static let ink = Color(hex: 0x0A0A0A)

    static let blush = Color(hex: 0xFFD9E0)
    static let onBlush = Color(hex: 0x3F0018)
    static let lilac = Color(hex: 0xE2E0F5)
    static let onLilac = Color(hex: 0x1A1A29)

    // MARK: Energy

    /// Photo-corner gold, as a **fill**. Static — a gold corner is the same
    /// colour in any light — and it always carries `onNeon` (near-black) text,
    /// so it stays legible on either theme.
    ///
    /// The token is still called `neon` because it names a *role* — the one
    /// colour that means "active" — and renaming it would touch a hundred call
    /// sites to say nothing new. The acid lime it used to hold was the single
    /// loudest reason this app read as a dashboard rather than an album.
    static let neon = Color(hex: 0xFFB300)
    static let neonDim = Color(hex: 0xD19200)
    static let onNeon = Color(hex: 0x141414)

    /// Gold as **text or a stroke on a surface**. `#FFB300` on warm paper is
    /// well under 4.5:1, so this drops to the album's own deep amber there.
    /// Use this anywhere the accent is the foreground; use `neon` for fills.
    static let accent = Color.adaptive(light: 0x8A5A00, dark: 0xFFB300)

    /// The one red. Destructive actions and unread badges — nothing decorative.
    static let pink = Color(hex: 0xE5484D)
    static let onPink = Color(hex: 0xFFFFFF)

    /// Text sitting on a dark scrim over a photograph — a board cover, a hero
    /// tile. Static, because the scrim is dark in both themes: light mode
    /// changes the page behind the card, not the gradient painted over the
    /// picture inside it.
    static let onScrim = Color(hex: 0xFFFFFF)
    static let onScrimVariant = Color(hex: 0xFFFFFF, opacity: 0.78)
    /// Red as foreground on a surface.
    static let pinkAccent = Color.adaptive(light: 0xC22026, dark: 0xF2555A)

    // MARK: Hairlines and shadows (adapt)

    /// Backing for floating chrome (the dock, the profile pill, the settings
    /// button). Opaque enough that a label on it stays legible no matter what is
    /// scrolling behind — a black cover photo in light mode, a white paper note
    /// in dark mode.
    static let chromeSurface = Color.adaptive(light: 0xFCFCFB, dark: 0x161618, lightAlpha: 0.95, darkAlpha: 0.92)

    /// Light mode leans on hairlines harder than dark does: dark separates
    /// surfaces by making them lighter, light mode has much less headroom above
    /// the page and needs the edge to do the work instead.
    static let hairline = Color.adaptive(light: 0x000000, dark: 0xFFFFFF, lightAlpha: 0.14, darkAlpha: 0.10)
    static let hairlineBright = Color.adaptive(light: 0x000000, dark: 0xFFFFFF, lightAlpha: 0.22, darkAlpha: 0.20)

    /// Shadows tuned per theme. A 70%-black shadow reads as depth on a dark
    /// wall and as dirt on a light one.
    static let shadowHeavy = Color.adaptive(light: 0x000000, dark: 0x000000, lightAlpha: 0.20, darkAlpha: 0.72)
    static let shadowSoft = Color.adaptive(light: 0x000000, dark: 0x000000, lightAlpha: 0.14, darkAlpha: 0.55)
    static let shadowContact = Color.adaptive(light: 0x000000, dark: 0x000000, lightAlpha: 0.10, darkAlpha: 0.35)
    /// The hard vinyl-sticker shadow. Stays dark in both themes — it is the
    /// object's own cast shadow, not ambient room light.
    static let shadowSticker = Color.adaptive(light: 0x000000, dark: 0x000000, lightAlpha: 0.55, darkAlpha: 1.0)
}

/// Radius scale. "Round Eight" is the professional baseline; larger radii are
/// reserved for tactile objects that should read as soft physical shapes.
enum Radius {
    /// Photo prints and small chips — near-square, like a real print.
    static let print: CGFloat = 4
    /// The professional baseline from the handoff.
    static let eight: CGFloat = 8
    static let card: CGFloat = 16
    static let panel: CGFloat = 24
    /// Widgets on the Personality Board.
    static let widget: CGFloat = 32
}

/// 8pt base unit, per the handoff spacing scale.
enum Space {
    static let unit: CGFloat = 8
    static let objectGap: CGFloat = 16
    static let canvasMargin: CGFloat = 32
    static let stickerPadding: CGFloat = 12
    /// Clearance the floating nav bar needs at the bottom of every scroll view.
    static let dockClearance: CGFloat = 132
    /// Clearance the floating top bar needs at the top of every scroll view.
    static let topBarClearance: CGFloat = 76
}

/// Clearance for the floating chrome.
///
/// These are not ordinary padding. They are the room a scroll view leaves for a
/// control that floats *over* it, which means the number has to track the size
/// of that control — and the control contains text, so it grows with the
/// reader's text size. A fixed 76pt was correct exactly once, at the default
/// setting; one notch up and the profile pill started sitting on the first card.
private struct TopBarClearance: ViewModifier {

    /// Scaled on the profile pill's own ramp — `labelCaps` rides `.caption`.
    @ScaledMetric(relativeTo: .caption) private var clearance: CGFloat = Space.topBarClearance

    var extra: CGFloat = 0

    func body(content: Content) -> some View {
        content.padding(.top, clearance + extra)
    }
}

private struct DockClearance: ViewModifier {

    /// `labelTiny` rides `.caption2`.
    @ScaledMetric(relativeTo: .caption2) private var clearance: CGFloat = Space.dockClearance

    func body(content: Content) -> some View {
        // The dock itself stops growing at the largest non-accessibility step,
        // so the room reserved for it stops there too. Without the cap the
        // accessibility sizes would push a hole into the bottom of every scroll
        // view that no longer has a dock in it.
        content.padding(.bottom, min(clearance, Space.dockClearance * 1.5))
    }
}

extension View {
    /// Leaves room for the floating profile pill and settings button.
    func topBarClearance(extra: CGFloat = 0) -> some View {
        modifier(TopBarClearance(extra: extra))
    }

    /// Leaves room for the floating dock.
    func dockClearance() -> some View {
        modifier(DockClearance())
    }
}
