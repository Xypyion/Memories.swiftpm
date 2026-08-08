import SwiftUI
import UIKit

/// A procedurally generated stand-in for a photograph.
///
/// The app ships with zero image assets on purpose: it has to look full and
/// alive on first launch, on any device, with no download and no asset
/// pipeline. Each texture is derived from a stable seed, so a given memory
/// always looks the same. Real photos imported from the library replace these
/// entirely — see `MemoryImage`.
struct MemoryTexture: View {

    let seed: Int

    var body: some View {
        let recipe = TextureRecipe(seed: seed)

        ZStack {
            LinearGradient(
                colors: [recipe.base, recipe.shade],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ForEach(recipe.blobs) { blob in
                Ellipse()
                    .fill(blob.color)
                    .frame(width: blob.size.width, height: blob.size.height)
                    .blur(radius: blob.blur)
                    .offset(x: blob.offset.width, y: blob.offset.height)
                    .blendMode(.screen)
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .center,
                endPoint: .bottom
            )

            Grain(seed: seed)
                .opacity(0.16)
                .blendMode(.overlay)
        }
        .compositingGroup()
        .clipped()
    }
}

/// Flash-photography grain. Small enough to be subtle, present enough that the
/// surface doesn't read as a flat CSS gradient.
private struct Grain: View {

    let seed: Int

    var body: some View {
        Canvas { context, size in
            var rng = SeededGenerator(seed: seed &+ 977)
            for _ in 0 ..< 220 {
                let x = CGFloat.random(in: 0 ... max(size.width, 1), using: &rng)
                let y = CGFloat.random(in: 0 ... max(size.height, 1), using: &rng)
                let r = CGFloat.random(in: 0.4 ... 1.6, using: &rng)
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

    struct Blob: Identifiable {
        let id = UUID()
        var color: Color
        var size: CGSize
        var offset: CGSize
        var blur: CGFloat
    }

    let base: Color
    let shade: Color
    let blobs: [Blob]

    init(seed: Int) {
        var rng = SeededGenerator(seed: seed)

        let hue = Double.random(in: 0 ... 1, using: &rng)
        let drift = Double.random(in: 0.08 ... 0.34, using: &rng)
        let hue2 = (hue + drift).truncatingRemainder(dividingBy: 1)

        base = Color(hue: hue, saturation: 0.52, brightness: 0.46)
        shade = Color(hue: hue2, saturation: 0.62, brightness: 0.16)

        blobs = (0 ..< 3).map { _ in
            let h = (hue + Double.random(in: -0.18 ... 0.18, using: &rng) + 1)
                .truncatingRemainder(dividingBy: 1)
            return Blob(
                color: Color(hue: h, saturation: 0.72, brightness: 0.85)
                    .opacity(Double.random(in: 0.28 ... 0.55, using: &rng)),
                size: CGSize(
                    width: Double.random(in: 120 ... 300, using: &rng),
                    height: Double.random(in: 120 ... 280, using: &rng)
                ),
                offset: CGSize(
                    width: Double.random(in: -120 ... 120, using: &rng),
                    height: Double.random(in: -120 ... 120, using: &rng)
                ),
                blur: Double.random(in: 28 ... 70, using: &rng)
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

    var body: some View {
        Group {
            if let name = payload.imageName, let image = ImageStore.image(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                MemoryTexture(seed: seed)
            }
        }
        .contrast(1.08)
        .saturation(1.05)
    }
}
