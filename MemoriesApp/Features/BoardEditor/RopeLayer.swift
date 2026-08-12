import SwiftUI

/// Every connection on a board — twine and arrows.
///
/// This is the **only** view that observes `CanvasLiveState`, and that is the
/// point. While an item is being dragged the connection has to keep up with it
/// in real time — a rope that snapped to its new position on release would
/// destroy the illusion that these things are physically tied together. So this
/// view re-renders at gesture rate, and nothing else does. It draws a handful of
/// `Shape`s, which is cheap enough to do 120 times a second.
///
/// No explicit zIndex: declaration order inside the canvas `ZStack` already puts
/// connections above the backdrop and below every item. A negative zIndex would
/// push them behind the opaque backdrop and they would vanish.
struct RopeLayer: View {

    let ropes: [RopeConnection]
    let positions: [UUID: CGPoint]
    let canvasSize: CGSize
    /// The rope tied a moment ago, if any. It is the one that plays the
    /// slack-to-taut animation; every other rope draws at its stored sag.
    var justTiedID: UUID?

    @ObservedObject var live: CanvasLiveState

    var body: some View {
        ZStack {
            ForEach(ropes) { rope in
                if let a = positions[rope.a], let b = positions[rope.b] {
                    connection(
                        rope,
                        from: live.resolvedPosition(of: rope.a, base: a),
                        to: live.resolvedPosition(of: rope.b, base: b)
                    )
                    // Cutting removes the rope from the model immediately, so
                    // the fade is what makes it read as a deliberate sever
                    // rather than a glitch.
                    .transition(.opacity)
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func connection(_ rope: RopeConnection, from: CGPoint, to: CGPoint) -> some View {
        switch rope.resolvedStyle {
        case .twine:
            TwineConnection(rope: rope, from: from, to: to, playsTieAnimation: rope.id == justTiedID)
        case .arrow:
            ArrowConnector(from: from, to: to)
        }
    }
}

/// A single twine rope, with the signature "just tied" moment.
///
/// A freshly tied rope enters slack and springs taut. Every other rope renders
/// at its stored sag with no animation at all, so opening a board with existing
/// connections does not set the whole canvas swinging.
private struct TwineConnection: View {

    let rope: RopeConnection
    let from: CGPoint
    let to: CGPoint
    let playsTieAnimation: Bool

    @Environment(\.motionPolicy) private var motion

    /// Extra sag on top of the rope's stored value. Starts positive on a freshly
    /// tied rope and springs to zero.
    @State private var extraSag: CGFloat

    init(rope: RopeConnection, from: CGPoint, to: CGPoint, playsTieAnimation: Bool) {
        self.rope = rope
        self.from = from
        self.to = to
        self.playsTieAnimation = playsTieAnimation
        _extraSag = State(initialValue: playsTieAnimation ? rope.sag * 1.7 : 0)
    }

    var body: some View {
        RopeView(from: from, to: to, sag: rope.sag + extraSag)
            .onAppear {
                guard extraSag != 0 else { return }
                withAnimation(motion.animation(Motion.pop)) { extraSag = 0 }
            }
    }
}
