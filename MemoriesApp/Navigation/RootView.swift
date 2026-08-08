import SwiftUI

struct RootView: View {

    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.void
                .ignoresSafeArea()

            content
                .ignoresSafeArea(.container, edges: .bottom)

            LiquidGlassTabBar(
                selection: $store.tab,
                badges: store.invites.isEmpty ? [] : [.friends]
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: store.tab)
    }

    @ViewBuilder
    private var content: some View {
        switch store.tab {
        case .board:
            boardTab
                .transition(.opacity)

        case .memories:
            MemoriesGridView()
                .transition(.opacity)

        case .friends:
            FriendsHubView()
                .transition(.opacity)

        case .profile:
            ProfileBoardView()
                .transition(.opacity)
        }
    }

    /// The Board tab is two states, not two screens: the gallery of boards, and
    /// one board opened on the canvas. Keeping it inside a single tab means the
    /// dock never disappears and the user never loses their place.
    @ViewBuilder
    private var boardTab: some View {
        if let openID = store.openBoardID, store.board(id: openID) != nil {
            BoardEditorView(boardID: openID) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
                    store.openBoardID = nil
                }
            }
            .transition(
                .asymmetric(
                    insertion: .scale(scale: 0.94).combined(with: .opacity),
                    removal: .opacity
                )
            )
        } else {
            GalleryView()
                .transition(.opacity)
        }
    }
}
