import SwiftUI

/// Live, in-flight gesture state for the board canvas.
///
/// **Why this exists.** Dragging an item used to write `item.position` straight
/// through the store binding on every gesture frame. On a 120Hz iPad that is
/// ~120 mutations a second to `AppStore`, and because `AppStore` is a single
/// `ObservableObject`, every one of them fired `objectWillChange` and invalidated
/// *every subscribed view in the app* — the gallery, the tab bar, the friends
/// hub, every other item on the board. That is the Boards lag, and no amount of
/// lazy loading would have fixed it.
///
/// Now an item drag touches two things: the item's own local `@State` (so it
/// moves), and this object (so the twine follows it). The store is written
/// **once**, when the gesture ends.
///
/// The subtlety that makes it work: hold this in the editor with `@State`, not
/// `@StateObject`. `@State` keeps the reference alive across renders *without*
/// subscribing to it, so the editor — which owns the `ForEach` over every item —
/// does not re-render. Only `RopeLayer`, which declares `@ObservedObject`,
/// redraws at gesture rate, and it is two `Shape`s.
final class CanvasLiveState: ObservableObject {

    /// The item currently under the user's finger, if any.
    @Published private(set) var draggingID: UUID?
    /// Its displacement from the position stored in the model.
    @Published private(set) var offset: CGSize = .zero

    func begin(_ id: UUID) {
        draggingID = id
        offset = .zero
    }

    func update(_ translation: CGSize) {
        offset = translation
    }

    func end() {
        draggingID = nil
        offset = .zero
    }

    /// A model position adjusted for any drag in flight.
    func resolvedPosition(of id: UUID, base: CGPoint) -> CGPoint {
        guard draggingID == id else { return base }
        return CGPoint(x: base.x + offset.width, y: base.y + offset.height)
    }
}
