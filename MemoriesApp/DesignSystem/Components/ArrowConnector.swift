import SwiftUI

/// A drawn arrow between two objects.
///
/// The board's second connector. Twine says "these belong together"; an arrow
/// says "this one leads to that one" — it carries direction, which twine cannot.
/// It follows the same gentle curve as the rope so the two read as members of
/// one family, but it hangs far less: an arrow is drawn, not tied, so it should
/// not sag under its own weight.
struct ArrowConnector: View {

    let from: CGPoint
    let to: CGPoint
    var curvature: CGFloat = 0.12
    var tint: Color = Palette.accent
    var lineWidth: CGFloat = 3.5

    var body: some View {
        ZStack {
            ArrowShaft(from: from, to: to, curvature: curvature)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            ArrowHead(from: from, to: to, curvature: curvature)
                .fill(tint)
        }
        .allowsHitTesting(false)
    }
}

/// Shared curve maths, so the shaft and the head cannot disagree about where the
/// line ends or which way it is pointing.
enum ArrowGeometry {

    static func control(from: CGPoint, to: CGPoint, curvature: CGFloat) -> CGPoint {
        let span = hypot(to.x - from.x, to.y - from.y)
        let midpoint = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)

        // Bow perpendicular to the line rather than straight down: an arrow is a
        // deliberate gesture, not something obeying gravity.
        let dx = to.x - from.x
        let dy = to.y - from.y
        let length = max(span, 0.0001)
        let normal = CGPoint(x: -dy / length, y: dx / length)

        return CGPoint(
            x: midpoint.x + normal.x * span * curvature,
            y: midpoint.y + normal.y * span * curvature
        )
    }

    static func point(t: CGFloat, from: CGPoint, control: CGPoint, to: CGPoint) -> CGPoint {
        let mt = 1 - t
        return CGPoint(
            x: mt * mt * from.x + 2 * mt * t * control.x + t * t * to.x,
            y: mt * mt * from.y + 2 * mt * t * control.y + t * t * to.y
        )
    }

    static func tangent(t: CGFloat, from: CGPoint, control: CGPoint, to: CGPoint) -> CGPoint {
        CGPoint(
            x: 2 * (1 - t) * (control.x - from.x) + 2 * t * (to.x - control.x),
            y: 2 * (1 - t) * (control.y - from.y) + 2 * t * (to.y - control.y)
        )
    }
}

private struct ArrowShaft: Shape {

    var from: CGPoint
    var to: CGPoint
    var curvature: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard hypot(to.x - from.x, to.y - from.y) > 1 else { return path }

        let control = ArrowGeometry.control(from: from, to: to, curvature: curvature)
        // Stop short of the target so the head, not the line, meets the object.
        let tip = ArrowGeometry.point(t: 0.92, from: from, control: control, to: to)

        path.move(to: from)
        path.addQuadCurve(to: tip, control: control)
        return path
    }
}

private struct ArrowHead: Shape {

    var from: CGPoint
    var to: CGPoint
    var curvature: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard hypot(to.x - from.x, to.y - from.y) > 1 else { return path }

        let control = ArrowGeometry.control(from: from, to: to, curvature: curvature)
        let tip = ArrowGeometry.point(t: 0.97, from: from, control: control, to: to)
        let tangent = ArrowGeometry.tangent(t: 0.97, from: from, control: control, to: to)

        let length = max(hypot(tangent.x, tangent.y), 0.0001)
        let direction = CGPoint(x: tangent.x / length, y: tangent.y / length)
        let normal = CGPoint(x: -direction.y, y: direction.x)

        let headLength: CGFloat = 20
        let headWidth: CGFloat = 9

        let base = CGPoint(x: tip.x - direction.x * headLength, y: tip.y - direction.y * headLength)

        path.move(to: tip)
        path.addLine(to: CGPoint(x: base.x + normal.x * headWidth, y: base.y + normal.y * headWidth))
        path.addLine(to: CGPoint(x: base.x - normal.x * headWidth, y: base.y - normal.y * headWidth))
        path.closeSubpath()
        return path
    }
}
