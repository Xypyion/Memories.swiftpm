import SwiftUI

// Depth comes from **object** shadows only.
//
// Paper, photos, notes and cards cast shadows because they are things lying on a
// surface — that is the design. Foreground chrome does not: no glows on buttons,
// no shadows behind icons or text, no halo on vector decorations. A glow on a
// control is decoration pretending to be depth, and it costs an offscreen render
// pass per frame to draw.
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
}
