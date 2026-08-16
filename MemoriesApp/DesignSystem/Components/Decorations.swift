import SwiftUI

// Cut-out magazine vectors. These exist to fill the gaps between memories so a
// sparse board still reads as composed rather than empty.

struct StarShape: Shape {

    var points: Int = 5
    var innerRatio: CGFloat = 0.42

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        let step = .pi / CGFloat(points)

        for index in 0 ..< (points * 2) {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = CGFloat(index) * step - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

/// The four-point sparkle used as a "this is special" mark.
struct SparkleShape: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX + w * 0.12, y: rect.midY - h * 0.12)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.midX + w * 0.12, y: rect.midY + h * 0.12)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control: CGPoint(x: rect.midX - w * 0.12, y: rect.midY + h * 0.12)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.midX - w * 0.12, y: rect.midY - h * 0.12)
        )
        path.closeSubpath()
        return path
    }
}

/// A hand-drawn-feeling squiggle.
struct SquiggleShape: Shape {

    var waves: Int = 3

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let segment = rect.width / CGFloat(waves)
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        for index in 0 ..< waves {
            let startX = rect.minX + CGFloat(index) * segment
            let direction: CGFloat = index.isMultiple(of: 2) ? -1 : 1
            path.addQuadCurve(
                to: CGPoint(x: startX + segment, y: rect.midY),
                control: CGPoint(x: startX + segment / 2, y: rect.midY + direction * rect.height / 2)
            )
        }
        return path
    }
}

/// A hand-drawn circle — deliberately not closed, deliberately elliptical.
struct HandDrawnRing: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(-20),
            endAngle: .degrees(310),
            clockwise: false
        )
        return path
    }
}

/// Renders one of the decorative marks a user can drop onto a board.
struct DecorationView: View {

    let kind: DecorationKind
    var size: CGFloat = 80
    /// Adaptive by default, so a mark is legible on a light board and a dark
    /// one. Callers that sit on a fixed ground pass their own colour.
    var color: Color = Palette.onSurface

    var body: some View {
        Group {
            switch kind {
            case .star:
                // Filled, not stroked. A thin outlined star floating on a dark
                // board reads as clip art dropped into the design; the same
                // shape as a solid reads as a piece of paper someone cut out,
                // which is what the rest of this board is made of.
                StarShape()
                    .fill(color)
            case .sparkle:
                SparkleShape()
                    .fill(color)
            case .squiggle:
                SquiggleShape()
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            case .ring:
                HandDrawnRing()
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            case .arrow:
                ArrowShape()
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: kind == .squiggle ? size * 0.4 : size)
    }
}

/// A hand-drawn arrow: a curved shaft sweeping up to the right, with a head
/// that actually points where the shaft is going.
///
/// The head is the whole problem with drawing one of these. Barbs placed by eye
/// relative to the *frame* rather than to the shaft's direction of travel come
/// out lopsided, and at small sizes the shape stops reading as an arrow and
/// starts reading as a squiggle with a nick in it — which is what this was.
/// Both barbs here are set off the tangent at the tip, one either side, so the
/// head stays symmetrical about the direction the arrow is actually pointing.
struct ArrowShape: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Kept off the right edge: the stroke is drawn centred on the path, so
        // a tip at `maxX` loses half its width to clipping.
        let tip = CGPoint(x: rect.minX + w * 0.86, y: rect.minY + h * 0.16)

        path.move(to: CGPoint(x: rect.minX + w * 0.06, y: rect.minY + h * 0.86))
        path.addQuadCurve(
            to: tip,
            control: CGPoint(x: rect.minX + w * 0.52, y: rect.minY + h * 0.94)
        )

        // The head, as one continuous stroke through the tip rather than two
        // separate lines meeting at it — a join reads as drawn, two ends
        // reads as broken.
        path.move(to: CGPoint(x: rect.minX + w * 0.58, y: rect.minY + h * 0.31))
        path.addLine(to: tip)
        path.addLine(to: CGPoint(x: rect.minX + w * 0.90, y: rect.minY + h * 0.48))

        return path
    }
}

// `GlowBlob` — a blurred coloured circle floated behind headings — was deleted
// rather than retuned. It was decoration standing in for depth, it was the
// single largest source of the soft coloured haze this UI used to sit under,
// and every one of its six uses looked better as plain ground.
