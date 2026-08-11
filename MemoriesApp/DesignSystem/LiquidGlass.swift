import SwiftUI

/// The "Liquid Glass" treatment: a floating, blurred container with a hairline
/// edge.
///
/// **No drop shadow.** A shadow behind a `Material` forces the whole capsule
/// into an offscreen render pass on every frame that the content behind it
/// moves — which, for a bar floating over a scrolling list, is every frame. It
/// was the single most expensive thing about the navigation bar, and a
/// translucent pane over content already separates itself without one.
struct LiquidGlassBackground<S: InsettableShape>: ViewModifier {

    let shape: S
    var tint: Double
    var strokeOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(Color.white.opacity(tint), in: shape)
            .background(.ultraThinMaterial, in: shape)
            .overlay {
                shape.strokeBorder(Color.white.opacity(strokeOpacity), lineWidth: 1)
            }
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

/// Glass that guarantees its own contrast.
///
/// The floating bars sit over whatever happens to be behind them — a black photo
/// in light mode, a white paper note in dark mode. A pure `Material` samples that
/// content, so the bar's *label* colour and the bar's *backdrop* can disagree and
/// the text disappears. This lays an opaque theme surface over the blur, so the
/// label colour is always right for the theme regardless of the content behind.
struct SolidGlassBackground<S: InsettableShape>: ViewModifier {

    let shape: S

    func body(content: Content) -> some View {
        content
            .background(Palette.chromeSurface, in: shape)
            .background(.ultraThinMaterial, in: shape)
            .overlay {
                shape.strokeBorder(Palette.hairlineBright, lineWidth: 1)
            }
    }
}

extension View {

    func liquidGlass<S: InsettableShape>(
        _ shape: S,
        tint: Double = 0.05,
        strokeOpacity: Double = 0.20
    ) -> some View {
        modifier(LiquidGlassBackground(shape: shape, tint: tint, strokeOpacity: strokeOpacity))
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

    /// Use for floating chrome that must stay legible over arbitrary content.
    func solidGlass<S: InsettableShape>(_ shape: S) -> some View {
        modifier(SolidGlassBackground(shape: shape))
    }
}
