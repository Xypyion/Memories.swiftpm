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
    var color: Color = Palette.neon

    var body: some View {
        Group {
            switch kind {
            case .star:
                StarShape()
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            case .sparkle:
                SparkleShape()
                    .fill(color)
            case .squiggle:
                SquiggleShape()
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            case .ring:
                HandDrawnRing()
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            case .arrow:
                ArrowShape()
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: kind == .squiggle ? size * 0.4 : size)
    }
}

struct ArrowShape: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.2),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.move(to: CGPoint(x: rect.maxX - rect.width * 0.28, y: rect.minY + rect.height * 0.06))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.minY + rect.height * 0.42))
        return path
    }
}

/// A soft coloured bloom. Used behind headings and inside panels to break up
/// large fields of black without adding a visible surface.
struct GlowBlob: View {

    var color: Color = Palette.pink
    var size: CGFloat = 220
    var opacity: Double = 0.28

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: size * 0.34)
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}
