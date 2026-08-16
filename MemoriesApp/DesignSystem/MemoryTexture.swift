import SwiftUI
import UIKit

/// The stand-in for a photograph that hasn't been imported yet.
///
/// The app ships with zero image assets on purpose: it has to look full and
/// alive on first launch, on any device, with no download and no asset
/// pipeline. Each print is derived from a stable seed, so a given memory always
/// looks the same. Real photos imported from the library replace these
/// entirely — see `MemoryImage`.
///
/// **Why these are illustrations and not fake photographs.** Two earlier
/// versions tried to imitate a photo — blurred blobs, then gradients — and both
/// landed in the same place: a muddy rectangle that reads as a *broken image*,
/// which is the worst thing a scrapbook cover can read as. Nothing procedural
/// and cheap is going to pass for a photograph, so this stops trying. These are
/// flat two-colour prints, obviously drawn, composed from five forms a seed
/// picks between. An illustration that is clearly an illustration looks
/// deliberate; a gradient pretending to be a photograph looks broken.
///
/// It also keeps the app honest, which is a standing commitment here: nothing
/// on screen pretends to be something it isn't.
///
/// **Performance.** One `Canvas`, flat fills only. No blur, no blend mode, no
/// gradient — each of those forces its own offscreen render target, and a
/// gallery draws dozens of these at once.
struct MemoryTexture: View {

    let seed: Int
    var detail: Detail = .full

    enum Detail {
        /// Collage tiles, avatars, small widgets.
        case thumbnail
        /// Anything the user is looking at directly.
        case full
    }

    var body: some View {
        let print = PrintRecipe(seed: seed)

        Canvas(opaque: true, rendersAsynchronously: true) { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color(hex: print.palette.ground))
            )

            let mid = Color(hex: print.palette.mid)
            let mark = Color(hex: print.palette.mark)
            let w = size.width
            let h = size.height

            switch print.form {
            case .sun:
                // A horizon and a low sun. The disc sits above the line, never
                // centred on it — a bisected circle reads as a logo.
                context.fill(
                    Path(CGRect(x: 0, y: h * print.a, width: w, height: h)),
                    with: .color(mid)
                )
                let r = min(w, h) * 0.17
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: w * print.b - r,
                        y: h * print.a - r * 2.1,
                        width: r * 2,
                        height: r * 2
                    )),
                    with: .color(mark)
                )

            case .hills:
                // Two overlapping rises, the near one darker.
                let r1 = w * 0.52
                context.fill(
                    Path(ellipseIn: CGRect(x: -w * 0.1, y: h * print.a, width: r1 * 2, height: r1 * 2)),
                    with: .color(mid)
                )
                let r2 = w * 0.40
                context.fill(
                    Path(ellipseIn: CGRect(x: w * print.b, y: h * (print.a + 0.12), width: r2 * 2, height: r2 * 2)),
                    with: .color(mark)
                )

            case .arch:
                // A doorway. Flat, centred, generous margins.
                let aw = w * 0.44
                let ax = (w - aw) / 2
                let ay = h * 0.22
                context.fill(
                    Path(roundedRect: CGRect(x: ax, y: ay, width: aw, height: h - ay),
                         cornerSize: CGSize(width: aw / 2, height: aw / 2)),
                    with: .color(mid)
                )
                if detail == .full {
                    let iw = aw * 0.42
                    context.fill(
                        Path(roundedRect: CGRect(x: (w - iw) / 2, y: ay + aw * 0.34, width: iw, height: h),
                             cornerSize: CGSize(width: iw / 2, height: iw / 2)),
                        with: .color(mark)
                    )
                }

            case .rings:
                // Concentric, off-centre. An aperture, not a target.
                let cx = w * print.b
                let cy = h * print.a
                let outer = min(w, h) * 0.42
                context.fill(
                    Path(ellipseIn: CGRect(x: cx - outer, y: cy - outer, width: outer * 2, height: outer * 2)),
                    with: .color(mid)
                )
                if detail == .full {
                    let inner = outer * 0.46
                    context.fill(
                        Path(ellipseIn: CGRect(x: cx - inner, y: cy - inner, width: inner * 2, height: inner * 2)),
                        with: .color(mark)
                    )
                }

            case .split:
                // A diagonal field. The only form with no curve, so a gallery
                // of these has something straight in it.
                var path = Path()
                path.move(to: CGPoint(x: 0, y: h * print.a))
                path.addLine(to: CGPoint(x: w, y: h * (print.a - 0.28)))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.closeSubpath()
                context.fill(path, with: .color(mid))

                if detail == .full {
                    let r = min(w, h) * 0.13
                    context.fill(
                        Path(ellipseIn: CGRect(x: w * print.b - r, y: h * 0.18, width: r * 2, height: r * 2)),
                        with: .color(mark)
                    )
                }
            }
        }
        .clipped()
    }
}

/// The ink pairs. Muted enough that six of them on one screen read as a set,
/// saturated enough that a print is still the most colourful thing in a
/// deliberately neutral room.
private struct PrintPalette {
    let ground: UInt32
    let mid: UInt32
    let mark: UInt32

    static let all: [PrintPalette] = [
        PrintPalette(ground: 0x2E3A57, mid: 0x4C5F86, mark: 0xE8A13A),
        PrintPalette(ground: 0xA8503A, mid: 0xD08A5F, mark: 0xF2E2C9),
        PrintPalette(ground: 0x40584A, mid: 0x718C72, mark: 0xE4E0C4),
        PrintPalette(ground: 0x4E3049, mid: 0x855874, mark: 0xE3B4C0),
        PrintPalette(ground: 0x333D46, mid: 0x5A6B77, mark: 0xD5C5A4),
        PrintPalette(ground: 0x7E6130, mid: 0xB78E48, mark: 0xF0E2C0)
    ]
}

private struct PrintRecipe {

    enum Form: CaseIterable {
        case sun, hills, arch, rings, split
    }

    let palette: PrintPalette
    let form: Form
    /// Vertical placement, 0–1.
    let a: CGFloat
    /// Horizontal placement, 0–1.
    let b: CGFloat

    init(seed: Int) {
        var rng = SeededGenerator(seed: seed)

        palette = PrintPalette.all[Int.random(in: 0 ..< PrintPalette.all.count, using: &rng)]
        form = Form.allCases[Int.random(in: 0 ..< Form.allCases.count, using: &rng)]
        a = CGFloat.random(in: 0.52 ... 0.68, using: &rng)
        b = CGFloat.random(in: 0.28 ... 0.72, using: &rng)
    }
}

/// Draws a memory's picture: the user's imported photo if there is one,
/// otherwise the procedural print. Every photo surface in the app funnels
/// through here.
struct MemoryImage: View {

    let payload: PhotoPayload
    let seed: Int
    var detail: MemoryTexture.Detail = .full

    var body: some View {
        if let name = payload.imageName, let image = ImageStore.image(named: name) {
            // Only a real photograph gets the grade. The prints are drawn at
            // the colour they are meant to be, and pushing contrast on a flat
            // two-colour fill just posterises it.
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .contrast(1.06)
                .saturation(1.04)
        } else {
            MemoryTexture(seed: seed, detail: detail)
        }
    }
}
