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
/// Three rules govern every use of this palette:
///
/// 1. **Neon is a verb, not a surface.** `neon` is only ever applied to things
///    that are *active* or *actionable*. It is never a background for passive
///    content.
/// 2. **Paper is a break, not a theme.** `paper` marks physical objects that sit
///    *on* the board. Everything structural stays in the surface ladder.
/// 3. **Objects don't change colour when you turn the lights on.** Light mode
///    changes the *board* — the desk the memories are lying on — not the
///    memories. Paper stays paper, vinyl stays vinyl, photos stay photos. Only
///    the surface ladder and body text adapt. This is why the tactile language
///    survives the theme switch intact rather than becoming a washed-out
///    inversion of itself.
enum Palette {

    // MARK: Foundation — the elevation ladder (adapts)

    /// Level 0. The app background.
    static let void = Color.adaptive(light: 0xF4F3F0, dark: 0x000000)
    /// Level 0.5. The canvas field, so item shadows read against it.
    static let board = Color.adaptive(light: 0xEDECE8, dark: 0x050505)
    /// Level 1. Cards resting on the board.
    static let charcoal = Color.adaptive(light: 0xFFFFFF, dark: 0x101010)
    static let surface = Color.adaptive(light: 0xF7F6F3, dark: 0x131313)
    static let containerLow = Color.adaptive(light: 0xEFEEEA, dark: 0x1C1B1B)
    static let container = Color.adaptive(light: 0xE9E8E3, dark: 0x201F1F)
    static let containerHigh = Color.adaptive(light: 0xE3E2DD, dark: 0x2A2A2A)
    static let containerHighest = Color.adaptive(light: 0xDCDBD5, dark: 0x353534)

    // MARK: Content (adapts)

    static let onSurface = Color.adaptive(light: 0x14150F, dark: 0xE5E2E1)
    static let onSurfaceVariant = Color.adaptive(light: 0x565A48, dark: 0xC3C9AD)
    static let outline = Color.adaptive(light: 0x747963, dark: 0x8D937A)

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

    /// Neon as a **fill**. Static — the vinyl is the same colour in any light,
    /// and it always carries `onNeon` (near-black) text, so it stays legible on
    /// either theme.
    static let neon = Color(hex: 0xC8FF2E)
    static let neonDim = Color(hex: 0xA5D700)
    static let onNeon = Color(hex: 0x101010)

    /// Neon as **text or a stroke on a surface**. `#C8FF2E` is unreadable on a
    /// light background, so this darkens to the palette's own deep green there.
    /// Use this anywhere the accent is the foreground; use `neon` for fills.
    static let accent = Color.adaptive(light: 0x4E6700, dark: 0xC8FF2E)

    static let pink = Color(hex: 0xFF2E7E)
    static let onPink = Color(hex: 0xFFFFFF)

    /// Text sitting on a dark scrim over a photograph — a board cover, a hero
    /// tile. Static, because the scrim is dark in both themes: light mode
    /// changes the page behind the card, not the gradient painted over the
    /// picture inside it.
    static let onScrim = Color(hex: 0xFFFFFF)
    static let onScrimVariant = Color(hex: 0xFFFFFF, opacity: 0.76)
    /// Pink as foreground on a surface.
    static let pinkAccent = Color.adaptive(light: 0xC1004E, dark: 0xFF2E7E)

    // MARK: Hairlines and shadows (adapt)

    static let hairline = Color.adaptive(light: 0x000000, dark: 0xFFFFFF, lightAlpha: 0.10, darkAlpha: 0.10)
    static let hairlineBright = Color.adaptive(light: 0x000000, dark: 0xFFFFFF, lightAlpha: 0.18, darkAlpha: 0.20)

    /// Shadows tuned per theme. A 70%-black shadow reads as depth on a black
    /// board and as dirt on a white one.
    static let shadowHeavy = Color.adaptive(light: 0x1A1A14, dark: 0x000000, lightAlpha: 0.16, darkAlpha: 0.70)
    static let shadowSoft = Color.adaptive(light: 0x1A1A14, dark: 0x000000, lightAlpha: 0.12, darkAlpha: 0.55)
    static let shadowContact = Color.adaptive(light: 0x1A1A14, dark: 0x000000, lightAlpha: 0.10, darkAlpha: 0.35)
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
