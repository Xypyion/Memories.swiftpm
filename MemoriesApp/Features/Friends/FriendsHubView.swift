import SwiftUI

/// The Friends Hub.
///
/// Photo storage becomes a social ritual only if the social signal is *ambient*.
/// So this screen leads with who is here right now and what they just did,
/// rather than with a friend list — a list is a directory, and directories are
/// something you visit on purpose.
struct FriendsHubView: View {

    @EnvironmentObject private var store: AppStore

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 900

            ScrollView {
                VStack(alignment: .leading, spacing: Space.unit * 5) {
                    header

                    if isWide {
                        HStack(alignment: .top, spacing: Space.unit * 4) {
                            VStack(spacing: Space.unit * 4) {
                                invitesPanel
                                activeNow
                            }
                            .frame(width: geo.size.width * 0.32)

                            VStack(alignment: .leading, spacing: Space.unit * 5) {
                                recentActivity
                                commonMemories
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: Space.unit * 5) {
                            invitesPanel
                            activeNow
                            recentActivity
                            commonMemories
                        }
                    }
                }
                .padding(.horizontal, geo.size.width > 700 ? Space.canvasMargin : Space.unit * 2.5)
                .padding(.top, Space.unit * 6)
                .padding(.bottom, Space.dockClearance)
                .frame(maxWidth: 1440)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Palette.void)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 16) {
            AvatarView(
                name: store.profile.displayName,
                seed: store.profile.avatarSeed,
                size: 60,
                ring: .neon,
                imageName: store.profile.avatarImageName
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("Friends")
                    .textStyle(TypeScale.displayMD)
                    .foregroundStyle(.white)

                Text(store.profile.handle)
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.onSurfaceVariant)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: Invites

    @ViewBuilder
    private var invitesPanel: some View {
        VStack(alignment: .leading, spacing: Space.unit * 2) {
            SectionHeader(title: "Invites") {
                if !store.invites.isEmpty {
                    Text("\(store.invites.count)")
                        .textStyle(TypeScale.labelTiny)
                        .foregroundStyle(Palette.onPink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Palette.pink))
                }
            }

            VStack(spacing: 12) {
                if store.invites.isEmpty {
                    Text("No pending invites.")
                        .textStyle(TypeScale.bodyMD)
                        .foregroundStyle(Palette.onSurfaceVariant)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    ForEach(store.invites) { invite in
                        inviteRow(invite)
                    }
                }
            }
            .padding(20)
            .glassPanel(cornerRadius: Radius.panel)
            .overlay(alignment: .topTrailing) {
                GlowBlob(color: Palette.pink, size: 140, opacity: 0.22)
                    .offset(x: 40, y: -40)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
        }
    }

    private func inviteRow(_ invite: Invite) -> some View {
        HStack(spacing: 12) {
            if let friend = store.friend(id: invite.friendID) {
                AvatarView(name: friend.name, seed: friend.seed, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.name)
                        .textStyle(TypeScale.bodyMD)
                        .fontWeight(.semibold)
                        .foregroundStyle(Palette.onSurface)

                    Text("Wants to share “\(invite.boardName)”")
                        .textStyle(TypeScale.bodySM)
                        .foregroundStyle(Palette.onSurfaceVariant)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        store.acceptInvite(invite)
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Palette.onNeon)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Palette.neon))
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Accept invite")

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        store.declineInvite(invite)
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Palette.onSurfaceVariant)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Palette.containerHigh))
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Decline invite")
            }
        }
    }

    // MARK: Active now

    private var activeNow: some View {
        VStack(alignment: .leading, spacing: Space.unit * 2) {
            SectionHeader("Active now", accessory: "circle.fill")

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 76), spacing: 16)],
                alignment: .leading,
                spacing: 20
            ) {
                ForEach(store.friends) { friend in
                    VStack(spacing: 8) {
                        AvatarView(
                            name: friend.name,
                            seed: friend.seed,
                            size: 62,
                            ring: friend.ringStyle,
                            imageName: friend.avatarImageName
                        )
                        .opacity(friend.isActive ? 1 : 0.45)
                        .saturation(friend.isActive ? 1 : 0.2)
                        .overlay(alignment: .bottomTrailing) {
                            if friend.isActive {
                                PresenceDot(color: Palette.neon, size: 12)
                                    .padding(2)
                                    .background(Circle().fill(Palette.void))
                            }
                        }

                        Text(friend.name.split(separator: " ").first.map(String.init) ?? friend.name)
                            .textStyle(TypeScale.labelTiny)
                            .foregroundStyle(friend.isActive ? Palette.onSurface : Palette.onSurfaceVariant)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    // MARK: Activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: Space.unit * 2) {
            SectionHeader("Recent activity")

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 280), spacing: Space.objectGap)],
                spacing: Space.objectGap
            ) {
                ForEach(store.activity) { event in
                    ActivityCard(event: event, friend: store.friend(id: event.friendID))
                }
            }
        }
    }

    // MARK: Common memories

    private var commonMemories: some View {
        VStack(alignment: .leading, spacing: Space.unit * 2) {
            SectionHeader("Common memories")

            CommonMemoriesBoard(
                boards: store.boards.filter { !$0.collaborators.isEmpty },
                store: store
            )
        }
    }
}

/// One event in the stream. Photo-bearing events show the photos, because "Leo
/// added 3 photos" is not news — the photos are.
struct ActivityCard: View {

    let event: ActivityEvent
    let friend: Friend?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                if let friend {
                    AvatarView(name: friend.name, seed: friend.seed, size: 32)
                }

                // Two lines rather than one styled paragraph: the board name is
                // the tappable idea in this sentence, so it gets its own line
                // instead of being a coloured run buried mid-clause.
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(friend?.name ?? "Someone") \(event.verb)")
                        .textStyle(TypeScale.bodySM)
                        .foregroundStyle(Palette.onSurfaceVariant)
                        .lineLimit(2)

                    Text(event.boardName)
                        .textStyle(TypeScale.bodySM)
                        .fontWeight(.semibold)
                        .foregroundStyle(Palette.neon)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            if !event.photoSeeds.isEmpty {
                HStack(spacing: 8) {
                    ForEach(event.photoSeeds, id: \.self) { seed in
                        MemoryTexture(seed: seed)
                            .frame(height: 92)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.eight, style: .continuous))
                    }
                }
            }

            Text(RelativeTime.string(for: event.date).uppercased())
                .textStyle(TypeScale.labelTiny)
                .foregroundStyle(Palette.onSurfaceVariant.opacity(0.8))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: Radius.panel)
    }
}

/// Shared boards laid out as a messy pile rather than a row of tiles — the same
/// free-form language as the canvas, used here to say "these are collective
/// objects, not records".
struct CommonMemoriesBoard: View {

    let boards: [Board]
    let store: AppStore

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(boards.indices, id: \.self) { index in
                    let board = boards[index]
                    let layout = PileLayout(index: index, canvas: geo.size)

                    PiledBoardCard(
                        board: board,
                        collaborators: store.collaborators(for: board),
                        width: layout.width
                    )
                    .rotationEffect(.degrees(layout.rotation))
                    .position(layout.position)
                    .zIndex(Double(index))
                    .onTapGesture {
                        store.openBoardID = board.id
                        store.tab = .board
                    }
                }

                DecorationView(kind: .sparkle, size: 42, color: Palette.pink)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.86)
                    .opacity(0.5)
                    .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Palette.charcoal)
            .clipShape(RoundedRectangle(cornerRadius: Radius.widget, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.widget, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            }
        }
        .frame(height: 420)
    }
}

private struct PileLayout {

    let width: CGFloat
    let position: CGPoint
    let rotation: Double

    init(index: Int, canvas: CGSize) {
        let slots: [(x: CGFloat, y: CGFloat, w: CGFloat, r: Double)] = [
            (0.24, 0.46, 0.30, -5),
            (0.58, 0.34, 0.26, 4),
            (0.78, 0.62, 0.24, -3),
            (0.42, 0.70, 0.22, 7)
        ]
        let slot = slots[index % slots.count]

        width = max(140, canvas.width * slot.w)
        position = CGPoint(x: canvas.width * slot.x, y: canvas.height * slot.y)
        rotation = slot.r
    }
}

private struct PiledBoardCard: View {

    let board: Board
    let collaborators: [Friend]
    let width: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            BoardCollage(board: board)
                .frame(width: width, height: width * 1.15)
                .clipShape(RoundedRectangle(cornerRadius: Radius.print, style: .continuous))

            Text(board.title.uppercased())
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.onPaper)
                .lineLimit(1)
                .padding(.top, 12)
                .padding(.bottom, 4)
        }
        .padding(10)
        .background(Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: Radius.eight, style: .continuous))
        .paperShadow()
        .overlay(alignment: .top) {
            PushPin()
                .offset(y: -11)
        }
        .overlay(alignment: .bottomTrailing) {
            if !collaborators.isEmpty {
                FacePile(people: collaborators, size: 26, maxVisible: 2, borderColor: Palette.void)
                    .padding(6)
                    .background(Capsule().fill(Palette.void))
                    .offset(x: 10, y: 12)
            }
        }
    }
}
