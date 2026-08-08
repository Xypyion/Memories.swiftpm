import SwiftUI

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
}

/// The single source of truth for colour in the app.
///
/// Two rules govern every use of this palette:
///
/// 1. **Neon is a verb, not a surface.** `neon` is only ever applied to things
///    that are *active* or *actionable* — the selected tab, a primary button,
///    a live-presence ring. It is never a background for passive content.
/// 2. **Paper is a break, not a theme.** `paper` marks physical objects
///    (photo mounts, notes) that sit *on* the board. Everything structural
///    stays in the void/charcoal ladder.
enum Palette {

    // MARK: Foundation — the elevation ladder

    /// Level 0. The board itself. Absolute black, per the handoff.
    static let void = Color(hex: 0x000000)
    /// Level 0.5. Used behind the free-form canvas so item shadows read.
    static let board = Color(hex: 0x050505)
    /// Level 1. Cards resting on the board.
    static let charcoal = Color(hex: 0x101010)
    static let surface = Color(hex: 0x131313)
    static let containerLow = Color(hex: 0x1C1B1B)
    static let container = Color(hex: 0x201F1F)
    static let containerHigh = Color(hex: 0x2A2A2A)
    static let containerHighest = Color(hex: 0x353534)

    // MARK: Content

    static let onSurface = Color(hex: 0xE5E2E1)
    static let onSurfaceVariant = Color(hex: 0xC3C9AD)
    static let outline = Color(hex: 0x8D937A)

    /// Level 2. Physical paper — photo mounts, polaroids, sticky notes.
    static let paper = Color(hex: 0xFAFAFA)
    static let onPaper = Color(hex: 0x101010)

    // MARK: Energy

    /// Level 3. Primary action, active state, brand.
    static let neon = Color(hex: 0xC8FF2E)
    static let neonDim = Color(hex: 0xA5D700)
    static let onNeon = Color(hex: 0x101010)

    /// Collaboration, reactions, urgent social signal.
    static let pink = Color(hex: 0xFF2E7E)
    static let onPink = Color(hex: 0xFFFFFF)

    // MARK: Note stock

    static let blush = Color(hex: 0xFFD9E0)
    static let onBlush = Color(hex: 0x3F0018)
    static let lilac = Color(hex: 0xE2E0F5)
    static let onLilac = Color(hex: 0x1A1A29)

    // MARK: Hairlines

    static let hairline = Color.white.opacity(0.10)
    static let hairlineBright = Color.white.opacity(0.20)
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
}
