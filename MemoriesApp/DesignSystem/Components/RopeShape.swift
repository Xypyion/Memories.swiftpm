import SwiftUI

/// Braided twine connecting two memories.
///
/// This is the signature object of the whole product, so it is drawn properly
/// rather than faked with a dashed line:
///
/// * The rope **sags** under its own weight (a quadratic curve with a
///   downward control point), so the connection reads as physical.
/// * Two strands are drawn 180° out of phase along the curve's normal, which
///   is what produces a real braid rather than a stripe.
/// * A dark core is drawn underneath so the strands appear to wrap around
///   something rather than float side by side.
struct RopeStrand: Shape {

    var from: CGPoint
    var to: CGPoint
    /// 0 = taut, 1 = very slack.
    var sag: CGFloat = 0.22
    /// Half-width of the braid.
    var amplitude: CGFloat = 3.5
    /// Number of twists across the span.
    var twists: CGFloat = 14
    /// Phase offset — pass `.pi` for the opposing strand.
    var phase: CGFloat = 0

    /// `sag` rides along with the endpoints so a rope can animate from slack to
    /// taut when it is first tied, instead of snapping to its final curve.
    var animatableData: AnimatablePair<AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>, CGFloat> {
        get {
            AnimatablePair(
                AnimatablePair(
                    AnimatablePair(from.x, from.y),
                    AnimatablePair(to.x, to.y)
                ),
                sag
            )
        }
        set {
            from = CGPoint(x: newValue.first.first.first, y: newValue.first.first.second)
            to = CGPoint(x: newValue.first.second.first, y: newValue.first.second.second)
            sag = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let span = hypot(to.x - from.x, to.y - from.y)
        guard span > 1 else { return path }

        // Control point pulled straight down — gravity, not a bezier flourish.
        let control = CGPoint(
            x: (from.x + to.x) / 2,
            y: (from.y + to.y) / 2 + span * sag
        )

        let steps = max(24, Int(span / 6))

        for step in 0 ... steps {
            let t = CGFloat(step) / CGFloat(steps)
            let point = quadPoint(t: t, a: from, b: control, c: to)
            let tangent = quadTangent(t: t, a: from, b: control, c: to)
            let length = max(hypot(tangent.x, tangent.y), 0.0001)
            let normal = CGPoint(x: -tangent.y / length, y: tangent.x / length)

            // Taper the braid to nothing at both ends so it looks tied off.
            let taper = sin(t * .pi)
            let wave = sin(t * twists * .pi + phase) * amplitude * taper

            let offset = CGPoint(
                x: point.x + normal.x * wave,
                y: point.y + normal.y * wave
            )

            if step == 0 {
                path.move(to: offset)
            } else {
                path.addLine(to: offset)
            }
        }

        return path
    }

    private func quadPoint(t: CGFloat, a: CGPoint, b: CGPoint, c: CGPoint) -> CGPoint {
        let mt = 1 - t
        return CGPoint(
            x: mt * mt * a.x + 2 * mt * t * b.x + t * t * c.x,
            y: mt * mt * a.y + 2 * mt * t * b.y + t * t * c.y
        )
    }

    private func quadTangent(t: CGFloat, a: CGPoint, b: CGPoint, c: CGPoint) -> CGPoint {
        let mt = 1 - t
        return CGPoint(
            x: 2 * mt * (b.x - a.x) + 2 * t * (c.x - b.x),
            y: 2 * mt * (b.y - a.y) + 2 * t * (c.y - b.y)
        )
    }
}

/// The full rope: shadow, dark core, two braided strands, and knots at each end.
struct RopeView: View {

    let from: CGPoint
    let to: CGPoint
    var sag: CGFloat = 0.22
    var tint: Color = Color(hex: 0xD8C9A3)

    private var core: RopeStrand {
        RopeStrand(from: from, to: to, sag: sag, amplitude: 0, twists: 0)
    }

    var body: some View {
        ZStack {
            core
                .stroke(Color.black.opacity(0.55), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .blur(radius: 5)
                .offset(y: 5)

            core
                .stroke(tint.opacity(0.35), style: StrokeStyle(lineWidth: 6, lineCap: .round))

            RopeStrand(from: from, to: to, sag: sag, phase: 0)
                .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))

            RopeStrand(from: from, to: to, sag: sag, phase: .pi)
                .stroke(tint.opacity(0.72), style: StrokeStyle(lineWidth: 4, lineCap: .round))

            Knot().position(from)
            Knot().position(to)
        }
        .allowsHitTesting(false)
    }

    private struct Knot: View {
        var body: some View {
            Circle()
                .fill(Color(hex: 0xB8A67F))
                .frame(width: 11, height: 11)
                .overlay(Circle().strokeBorder(Color.black.opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.6), radius: 3, y: 2)
        }
    }
}
