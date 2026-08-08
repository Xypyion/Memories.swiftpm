import SwiftUI

/// Every length of twine on a board.
///
/// This is the **only** view that observes `CanvasLiveState`, and that is the
/// point. While an item is being dragged the rope has to keep up with it in real
/// time — a rope that snapped to its new position on release would destroy the
/// illusion that these things are physically tied together. So this view
/// re-renders at gesture rate, and nothing else does. It draws at most a handful
/// of `Shape`s, which is cheap enough to do 120 times a second.
///
/// No explicit zIndex: declaration order inside the canvas `ZStack` already puts
/// ropes above the backdrop and below every item. A negative zIndex would push
/// them behind the opaque backdrop and they would vanish.
struct RopeLayer: View {

    let ropes: [RopeConnection]
    let positions: [UUID: CGPoint]
    let canvasSize: CGSize

    @ObservedObject var live: CanvasLiveState

    var body: some View {
        ZStack {
            ForEach(ropes) { rope in
                if let a = positions[rope.a], let b = positions[rope.b] {
                    RopeView(
                        from: live.resolvedPosition(of: rope.a, base: a),
                        to: live.resolvedPosition(of: rope.b, base: b),
                        sag: rope.sag
                    )
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .allowsHitTesting(false)
    }
}
