import SwiftUI

/// Your own profile.
///
/// Identity first, expression second, and every element on it does something.
/// The rule applied throughout: **nothing that looks tappable is inert.** Stats
/// jump to the tab they count, the edit button opens a real editor with Save and
/// Cancel, and Settings is one tap from here as well as from the top bar.
struct MyProfileView: View {

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var account: AccountStore
    @EnvironmentObject private var preferences: Preferences

    @State private var isEditing = false
    @State private var showsSettings = false
    @State private var toast: ToastMessage?

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 780

            ScrollView {
                VStack(spacing: Space.unit * 4) {
                    ScrollOffsetReporter()

                    if let user = account.account {
                        ProfileHeader(
                            displayName: user.displayName,
                            handle: user.handle,
                            bio: user.bio,
                            avatarSeed: user.avatarSeed,
                            avatarImageName: user.avatarImageName,
                            presence: .online,
                            joinedAt: user.joinedAt,
                            isGuest: user.isGuest,
                            isWide: isWide
                        )

                        if user.isGuest {
                            guestNotice
                        }

                        actionRow

                        ProfileStatsRow(stats: stats)

                        PersonalityBoardSection(
                            profile: store.profile,
                            isEditable: true,
                            onEdit: { isEditing = true }
                        )

                        BoardStrip(title: "Your boards", boards: store.boards) { board in
                            store.openBoardID = board.id
                            store.tab = .board
                        }

                        recentMemories
                    }
                }
                .padding(.horizontal, isWide ? Space.canvasMargin : Space.unit * 2.5)
                .topBarClearance(extra: Space.unit * 2)
                .dockClearance()
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .tracksScrollOffset()
            .background {
                Palette.void.ignoresSafeArea()
            }
        }
        .toast($toast)
        .sheet(isPresented: $isEditing) {
            if let user = account.account {
                ProfileEditor(account: user, profile: store.profile) { updatedAccount, updatedProfile in
                    account.update { $0 = updatedAccount }
                    store.profile = updatedProfile
                    toast = ToastMessage(text: "Profile updated")
                }
            }
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView()
        }
    }

    // MARK: Pieces

    private var guestNotice: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.badge.key")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Palette.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("You're browsing as a guest")
                    .textStyle(TypeScale.bodyMD)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.onSurface)

                Text("Pick a username to keep everything you've made.")
                    .textStyle(TypeScale.bodySM)
                    .foregroundStyle(Palette.onSurfaceVariant)
            }

            Spacer(minLength: 8)

            NeonButton(title: "Claim", isCompact: true) { isEditing = true }
        }
        .padding(18)
        .glassPanel(cornerRadius: Radius.card)
    }

    private var actionRow: some View {
        HStack(spacing: 14) {
            Button {
                isEditing = true
            } label: {
                Label("Edit profile", systemImage: "pencil")
                    .textStyle(TypeScale.bodyLG)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.onPaper)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .fill(Palette.paper)
                    )
                    .paperShadow()
            }
            .buttonStyle(PressableButtonStyle())

            GlassIconButton(icon: "gearshape", size: 56) { showsSettings = true }
                .accessibilityLabel("Settings")
        }
        .frame(maxWidth: 460)
    }

    private var stats: [ProfileStatsRow.Stat] {
        [
            ProfileStatsRow.Stat(value: store.boards.count, label: "Boards", icon: "square.grid.2x2") {
                store.openBoardID = nil
                store.tab = .board
            },
            ProfileStatsRow.Stat(
                value: store.allMemories.count,
                label: "Memories",
                icon: "photo.on.rectangle.angled"
            ) {
                store.tab = .memories
            },
            ProfileStatsRow.Stat(value: store.friends.count, label: "Friends", icon: "person.2") {
                store.tab = .friends
            }
        ]
    }

    private var recentMemories: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent memories")
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.onSurfaceVariant)

                Spacer()

                Button("See all") { store.tab = .memories }
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.accent)
            }

            let recent = Array(store.allMemories.prefix(8))

            if recent.isEmpty {
                Text("Open a board and drop a photo onto the canvas.")
                    .textStyle(TypeScale.bodyMD)
                    .foregroundStyle(Palette.onSurfaceVariant)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(recent) { entry in
                            Button {
                                store.openBoardID = entry.board.id
                                store.tab = .board
                            } label: {
                                MemoryImage(
                                    payload: entry.item.kind.photo ?? PhotoPayload(),
                                    seed: entry.item.seed,
                                    detail: .thumbnail
                                )
                                .frame(width: 96, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.eight, style: .continuous))
                                .rotationEffect(.degrees(Double((entry.item.seed % 7) - 3) * 0.8))
                            }
                            .buttonStyle(LiftButtonStyle())
                        }
                    }
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: Radius.widget)
    }
}
