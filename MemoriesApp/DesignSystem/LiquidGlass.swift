import SwiftUI

/// The "Liquid Glass" treatment: a floating, heavily blurred container with a
/// bright top edge and a dim bottom edge, so it reads as a curved pane of glass
/// catching light rather than a flat translucent rectangle.
struct LiquidGlassBackground<S: InsettableShape>: ViewModifier {

    let shape: S
    var tint: Double
    var strokeOpacity: Double
    var shadowRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Color.white.opacity(tint), in: shape)
            .background(.ultraThinMaterial, in: shape)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(strokeOpacity + 0.16),
                            Color.white.opacity(strokeOpacity * 0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            }
            .shadow(color: .black.opacity(0.45), radius: shadowRadius, x: 0, y: 14)
    }
}

/// A quieter, more opaque panel for content cards. Still blurred, but it holds
/// text at long reading lengths where full glass would not.
struct GlassPanelBackground<S: InsettableShape>: ViewModifier {

    let shape: S

    func body(content: Content) -> some View {
        content
            .background(Palette.charcoal.opacity(0.66), in: shape)
            .background(.ultraThinMaterial, in: shape)
            .overlay {
                shape.strokeBorder(Palette.hairline, lineWidth: 1)
            }
    }
}

extension View {

    func liquidGlass<S: InsettableShape>(
        _ shape: S,
        tint: Double = 0.05,
        strokeOpacity: Double = 0.20,
        shadowRadius: CGFloat = 28
    ) -> some View {
        modifier(
            LiquidGlassBackground(
                shape: shape,
                tint: tint,
                strokeOpacity: strokeOpacity,
                shadowRadius: shadowRadius
            )
        )
    }

    func liquidGlass(cornerRadius: CGFloat = Radius.panel) -> some View {
        liquidGlass(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    func glassPanel<S: InsettableShape>(_ shape: S) -> some View {
        modifier(GlassPanelBackground(shape: shape))
    }

    func glassPanel(cornerRadius: CGFloat = Radius.panel) -> some View {
        glassPanel(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
