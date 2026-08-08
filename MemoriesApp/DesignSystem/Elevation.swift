import SwiftUI

// Depth is the core of this system. Four levels, four distinct shadow
// signatures — a viewer should be able to tell what level a thing is on
// without reading its content.
//
// The shadow *colours* come from `Palette` so they adapt with the theme: the
// same 70%-black that reads as depth on a black board reads as grime on a white
// one.

extension View {

    /// Level 1 — a card resting on the board. Wide, soft, plus a tight contact
    /// shadow so the edge doesn't float.
    func tactileShadow() -> some View {
        self
            .shadow(color: Palette.shadowHeavy, radius: 18, x: 0, y: 12)
            .shadow(color: Palette.shadowContact, radius: 3, x: 0, y: 1)
    }

    /// Level 2 — paper and photos, lifted off the surface.
    func paperShadow() -> some View {
        self.shadow(color: Palette.shadowSoft, radius: 16, x: 0, y: 7)
    }

    /// Level 3 — a thick vinyl sticker. Hard offset, zero blur. This is what
    /// makes stickers read as *stuck on* rather than *printed in*.
    func stickerShadow() -> some View {
        self.shadow(color: Palette.shadowSticker, radius: 0, x: 2, y: 2)
    }

    /// Emissive halo for active/live elements. Never decorative — it means
    /// "this is on".
    func neonGlow(radius: CGFloat = 16, opacity: Double = 0.35) -> some View {
        self.shadow(color: Palette.neon.opacity(opacity), radius: radius)
    }

    func pinkGlow(radius: CGFloat = 16, opacity: Double = 0.35) -> some View {
        self.shadow(color: Palette.pink.opacity(opacity), radius: radius)
    }
}
