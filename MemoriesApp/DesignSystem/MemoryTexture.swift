import SwiftUI
import UIKit

/// A procedurally generated stand-in for a photograph.
///
/// The app ships with zero image assets on purpose: it has to look full and
/// alive on first launch, on any device, with no download and no asset
/// pipeline. Each texture is derived from a stable seed, so a given memory
/// always looks the same. Real photos imported from the library replace these
/// entirely — see `MemoryImage`.
///
/// **Performance.** The first version of this drew three `.blur()`-ed ellipses
/// through `.blendMode(.screen)` inside a `.compositingGroup()`, plus a 220-op
/// `Canvas` of grain — per texture. A board cover shows five of them, and the
/// gallery shows several covers, so scrolling the Boards tab was compositing
/// dozens of offscreen passes per frame. Blur and blend modes each force a
/// separate render target; gradients do not. This version is gradients only, and
/// grain is opt-in via `detail` so a 90pt thumbnail never pays for texture
/// nobody can see at that size.
struct MemoryTexture: View {

    let seed: Int
    var detail: Detail = .full

    enum Detail {
        /// Collage tiles, avatars, small widgets. Gradients only.
        case thumbnail
        /// Anything the user is looking at directly. Adds film grain.
        case full
    }

    var body: some View {
        let recipe = TextureRecipe(seed: seed)

        ZStack {
            LinearGradient(
                colors: [recipe.base, recipe.shade],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Radial gradients stand in for the old blurred blobs. Visually
            // near-identical, one draw call each, no offscreen pass.
            ForEach(recipe.blooms) { bloom in
                RadialGradient(
                    colors: [bloom.color, bloom.color.opacity(0)],
                    center: bloom.center,
                    startRadius: 0,
                    endRadius: bloom.radius
                )
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .center,
                endPoint: .bottom
            )

            if detail == .full {
                Grain(seed: seed).opacity(0.14)
            }
        }
        .clipped()
    }
}

/// Flash-photography grain. Enough to stop the surface reading as a flat CSS
/// gradient, cheap enough to draw at full size.
private struct Grain: View {

    let seed: Int

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: true) { context, size in
            var rng = SeededGenerator(seed: seed &+ 977)
            for _ in 0 ..< 120 {
                let x = CGFloat.random(in: 0 ... max(size.width, 1), using: &rng)
                let y = CGFloat.random(in: 0 ... max(size.height, 1), using: &rng)
                let r = CGFloat.random(in: 0.5 ... 1.6, using: &rng)
                let white = Double.random(in: 0.25 ... 1.0, using: &rng)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                    with: .color(.white.opacity(white))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

private struct TextureRecipe {

    struct Bloom: Identifiable {
        let id: Int
        var color: Color
        var center: UnitPoint
        var radius: CGFloat
    }

    let base: Color
    let shade: Color
    let blooms: [Bloom]

    init(seed: Int) {
        var rng = SeededGenerator(seed: seed)

        let hue = Double.random(in: 0 ... 1, using: &rng)
        let drift = Double.random(in: 0.08 ... 0.34, using: &rng)
        let hue2 = (hue + drift).truncatingRemainder(dividingBy: 1)

        base = Color(hue: hue, saturation: 0.52, brightness: 0.46)
        shade = Color(hue: hue2, saturation: 0.62, brightness: 0.16)

        blooms = (0 ..< 2).map { index in
            let h = (hue + Double.random(in: -0.18 ... 0.18, using: &rng) + 1)
                .truncatingRemainder(dividingBy: 1)
            return Bloom(
                id: index,
                color: Color(hue: h, saturation: 0.72, brightness: 0.9)
                    .opacity(Double.random(in: 0.30 ... 0.55, using: &rng)),
                center: UnitPoint(
                    x: Double.random(in: 0.15 ... 0.85, using: &rng),
                    y: Double.random(in: 0.15 ... 0.85, using: &rng)
                ),
                radius: CGFloat.random(in: 140 ... 320, using: &rng)
            )
        }
    }
}

/// Draws a memory's picture: the user's imported photo if there is one,
/// otherwise the procedural texture. Every photo surface in the app funnels
/// through here.
struct MemoryImage: View {

    let payload: PhotoPayload
    let seed: Int
    var detail: MemoryTexture.Detail = .full

    var body: some View {
        Group {
            if let name = payload.imageName, let image = ImageStore.image(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                MemoryTexture(seed: seed, detail: detail)
            }
        }
        .contrast(1.08)
        .saturation(1.05)
    }
}
