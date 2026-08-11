import SwiftUI

/// Reports how far a tab's scroll view has moved, so the floating top controls
/// can get out of the way.
///
/// A preference key rather than a shared observable: preferences travel *up* the
/// view tree to whoever is listening, which means each tab reports its own
/// offset and `RootView` reads whichever tab is on screen, with no store to keep
/// in sync and no cross-tab bleed.
enum ScrollSpace {
    static let name = "app.scroll"
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Drop this in as the first child of a tracked scroll view's content.
struct ScrollOffsetReporter: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: ScrollOffsetKey.self,
                value: geo.frame(in: .named(ScrollSpace.name)).minY
            )
        }
        .frame(height: 0)
    }
}

extension View {
    /// Apply to the `ScrollView` itself; pair with `ScrollOffsetReporter` at the
    /// top of its content.
    func tracksScrollOffset() -> some View {
        coordinateSpace(.named(ScrollSpace.name))
    }
}
