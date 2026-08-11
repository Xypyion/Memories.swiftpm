import SwiftUI

struct RootView: View {

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var account: AccountStore
    @EnvironmentObject private var preferences: Preferences

    /// Read here rather than in the `App` conformer: accessibility environment
    /// values are populated for the view tree, not reliably at scene level.
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @State private var showsSettings = false
    @State private var scrollOffset: CGFloat = 0

    /// One policy combining the system setting with the app's own override, so
    /// no view has to consult two sources to decide whether to animate.
    private var motionPolicy: MotionPolicy {
        MotionPolicy(
            systemPrefersReduced: systemReduceMotion,
            appPrefersReduced: preferences.reduceMotion
        )
    }

    var body: some View {
        ZStack {
            Palette.void.ignoresSafeArea()

            if account.isSignedIn {
                signedIn
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .environment(\.motionPolicy, motionPolicy)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: account.isSignedIn)
    }

    // MARK: Signed in

    private var signedIn: some View {
        ZStack(alignment: .bottom) {
            content
                .ignoresSafeArea(.container, edges: .bottom)

            // The board editor brings its own header, and the canvas needs the
            // room. Everywhere else the two controls float on top.
            if !isEditingBoard {
                VStack {
                    FloatingTopControls(
                        account: account.account,
                        isVisible: showsTopControls,
                        onOpenProfile: { store.tab = .profile },
                        onOpenSettings: { showsSettings = true }
                    )
                    Spacer()
                }
            }

            LiquidGlassTabBar(
                selection: $store.tab,
                badges: store.invites.isEmpty ? [] : [.friends]
            )
        }
        // The dock is chrome anchored to the screen, not to the text field. Left
        // to itself SwiftUI lifts it on top of the keyboard, where it covers the
        // very thing you are typing into.
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            scrollOffset = offset
        }
        .onChange(of: store.tab) { _, _ in
            // A new tab starts at its own top; don't inherit the last one's
            // scroll position for the purposes of hiding chrome.
            scrollOffset = 0
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: store.tab)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isEditingBoard)
        .sheet(isPresented: $showsSettings) {
            SettingsView()
        }
        .overlay {
            if !account.hasCompletedOnboarding {
                OnboardingOverlay {
                    account.completeOnboarding()
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }

    /// A small dead zone so a rubber-band bounce at the top doesn't flicker the
    /// controls in and out.
    private var showsTopControls: Bool {
        scrollOffset > -24
    }

    private var isEditingBoard: Bool {
        store.tab == .board && store.openBoardID != nil
    }

    @ViewBuilder
    private var content: some View {
        switch store.tab {
        case .board:
            boardTab
                .transition(.opacity)

        case .memories:
            MemoriesView()
                .transition(.opacity)

        case .friends:
            FriendsHubView()
                .transition(.opacity)

        case .profile:
            MyProfileView()
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
