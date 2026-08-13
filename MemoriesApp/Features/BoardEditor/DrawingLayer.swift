import SwiftUI

/// Freehand drawing on the board — Apple Pencil or finger.
///
/// Strokes are stored as points on the `Board`, not rasterised, so they stay
/// sharp at any zoom, erase individually, and cost a few floats each instead of
/// a bitmap. Everything is drawn in a single `Canvas`, which means a board with
/// two hundred strokes is still one draw pass rather than two hundred views.
///
/// Like item drags, an in-flight stroke lives in local `@State` and is committed
/// to the store once, on lift. Appending a point to the model at pencil sample
/// rate — up to 240 Hz — would be the item-drag performance bug all over again.
struct DrawingLayer: View {

    let strokes: [DrawnStroke]
    let liveStroke: DrawnStroke?

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, _ in
            for stroke in strokes {
                draw(stroke, in: &context)
            }
            if let liveStroke {
                draw(liveStroke, in: &context)
            }
        }
        .allowsHitTesting(false)
    }

    private func draw(_ stroke: DrawnStroke, in context: inout GraphicsContext) {
        guard stroke.points.count > 1 else {
            // A single tap is still a mark — draw it as a dot rather than
            // swallowing it.
            if let point = stroke.points.first {
                let radius = stroke.width / 2
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: point.x - radius,
                        y: point.y - radius,
                        width: stroke.width,
                        height: stroke.width
                    )),
                    with: .color(stroke.color.opacity(stroke.isHighlighter ? 0.32 : 1))
                )
            }
            return
        }

        var layer = context
        if stroke.isHighlighter {
            // Multiply so a highlighter tints what it crosses instead of hiding
            // it, which is the entire point of a highlighter.
            layer.blendMode = .multiply
            layer.opacity = 0.34
        }

        layer.stroke(
            smoothedPath(stroke.points),
            with: .color(stroke.color),
            style: StrokeStyle(
                lineWidth: stroke.width,
                lineCap: stroke.isHighlighter ? .square : .round,
                lineJoin: .round
            )
        )
    }

    /// Quadratic smoothing through the midpoints. Raw sampled points produce
    /// visible polygonal corners at speed; this costs nothing and removes them.
    private func smoothedPath(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }

        path.move(to: first)
        guard points.count > 2 else {
            for point in points.dropFirst() { path.addLine(to: point) }
            return path
        }

        for index in 1 ..< points.count - 1 {
            let current = points[index]
            let next = points[index + 1]
            let midpoint = CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)
            path.addQuadCurve(to: midpoint, control: current)
        }
        path.addLine(to: points[points.count - 1])
        return path
    }
}

/// The drawing tool state the editor holds while the pen is out.
struct DrawingTool: Equatable {

    enum Mode: String, CaseIterable, Identifiable {
        case pen, highlighter, eraser

        var id: String { rawValue }

        var title: String {
            switch self {
            case .pen: "Pen"
            case .highlighter: "Highlighter"
            case .eraser: "Eraser"
            }
        }

        var icon: String {
            switch self {
            case .pen: "pencil.tip"
            case .highlighter: "highlighter"
            case .eraser: "eraser"
            }
        }
    }

    var mode: Mode = .pen
    var colorHex: UInt32 = 0xC8FF2E
    var penWidth: CGFloat = 5
    var highlighterWidth: CGFloat = 26

    var width: CGFloat {
        mode == .highlighter ? highlighterWidth : penWidth
    }

    /// One ink. The name is a stored field rather than a comment beside the hex,
    /// because it is read aloud: VoiceOver announces the swatch by name, and a
    /// name in a comment cannot be announced and drifts the first time somebody
    /// reorders the list.
    struct Ink: Identifiable, Equatable {
        let hex: UInt32
        let name: String

        var id: UInt32 { hex }
    }

    /// Ink options. Deliberately short — a wall of swatches is slower to use
    /// than eight good ones, and these are picked to read on both a black and a
    /// white board.
    static let palette: [Ink] = [
        Ink(hex: 0xC8FF2E, name: "Neon"),
        Ink(hex: 0xFF2E7E, name: "Pink"),
        Ink(hex: 0xFFFFFF, name: "White"),
        Ink(hex: 0x111111, name: "Ink"),
        Ink(hex: 0x36C5F0, name: "Sky"),
        Ink(hex: 0xFFC53D, name: "Amber"),
        Ink(hex: 0x9B7BFF, name: "Violet"),
        Ink(hex: 0x3ED66B, name: "Green")
    ]
}
