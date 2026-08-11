import SwiftUI

/// The identity block at the top of any profile — yours or a friend's.
///
/// This is the piece the old app was missing. Previously the Profile tab opened
/// straight onto the Personality Board, which told you someone's *vibe* without
/// ever telling you who they were. Expression sits on top of identity; it
/// doesn't replace it.
struct ProfileHeader: View {

    let displayName: String
    let handle: String
    let bio: String
    let avatarSeed: Int
    let avatarImageName: String?
    var presence: OnlineStatus.Presence?
    var joinedAt: Date?
    var isGuest: Bool = false
    var isWide: Bool = true

    var body: some View {
        VStack(spacing: 18) {
            avatar

            VStack(spacing: 6) {
                Text(displayName)
                    .textStyle(isWide ? TypeScale.displayMD : TypeScale.headline)
                    .foregroundStyle(Palette.onSurface)
                    .multilineTextAlignment(.center)

                HStack(spacing: 10) {
                    Text(handle)
                        .textStyle(TypeScale.labelCaps)
                        .foregroundStyle(Palette.onSurfaceVariant)

                    if let presence {
                        PresenceBadge(presence: presence, compact: true)
                    }
                }

                if isGuest {
                    StickerBadge(text: "Guest", style: .paper, rotation: -1, shape: .pill)
                        .padding(.top, 4)
                }
            }

            if !bio.isEmpty {
                Text(bio)
                    .textStyle(TypeScale.bodyMD)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let joinedAt {
                Text("Keeping memories since \(joinedAt.formatted(.dateTime.month(.wide).year()))")
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.onSurfaceVariant.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var avatar: some View {
        AvatarView(
            name: displayName,
            seed: avatarSeed,
            size: isWide ? 152 : 116,
            ring: .neon,
            imageName: avatarImageName
        )
        .rotationEffect(.degrees(2))
        .tactileShadow()
        .overlay(alignment: .bottomTrailing) {
            if let presence, presence != .offline {
                OnlineStatus(presence: presence, size: 16, surround: Palette.void)
                    .offset(x: -6, y: -6)
            }
        }
    }
}

/// Three numbers that describe a person's shelf. Tappable, because a count the
/// user cannot act on is decoration.
struct ProfileStatsRow: View {

    struct Stat: Identifiable {
        let id = UUID()
        var value: Int
        var label: String
        var icon: String
        var action: (() -> Void)?
    }

    let stats: [Stat]

    var body: some View {
        HStack(spacing: Space.objectGap) {
            ForEach(stats) { stat in
                Button {
                    stat.action?()
                } label: {
                    VStack(spacing: 6) {
                        Text("\(stat.value)")
                            .textStyle(TypeScale.headline)
                            .foregroundStyle(Palette.onSurface)

                        Text(stat.label.uppercased())
                            .textStyle(TypeScale.labelTiny)
                            .foregroundStyle(Palette.onSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .glassPanel(cornerRadius: Radius.card)
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(stat.action == nil)
                .accessibilityLabel("\(stat.value) \(stat.label)")
            }
        }
    }
}

/// A horizontal shelf of boards. Used on both profiles.
struct BoardStrip: View {

    let title: String
    let boards: [Board]
    let onOpen: (Board) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.onSurfaceVariant)

            if boards.isEmpty {
                Text("Nothing here yet.")
                    .textStyle(TypeScale.bodyMD)
                    .foregroundStyle(Palette.onSurfaceVariant)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: Space.objectGap) {
                        ForEach(boards) { board in
                            Button {
                                onOpen(board)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    BoardCollage(board: board)
                                        .drawingGroup()
                                        .frame(width: 150, height: 110)
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                                        )

                                    Text(board.title)
                                        .textStyle(TypeScale.bodySM)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Palette.onSurface)
                                        .lineLimit(1)

                                    Text("\(board.memoryCount) memories")
                                        .textStyle(TypeScale.labelTiny)
                                        .foregroundStyle(Palette.onSurfaceVariant)
                                }
                                .frame(width: 150, alignment: .leading)
                            }
                            .buttonStyle(LiftButtonStyle())
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: Radius.widget)
    }
}
