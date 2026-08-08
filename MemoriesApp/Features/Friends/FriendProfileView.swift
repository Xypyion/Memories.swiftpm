import SwiftUI

/// Somebody else's profile.
///
/// Everything here is *derived* rather than invented: the boards you share, the
/// memories inside them, what they've actually done recently. A friend in this
/// app has never filled in a Personality Board, so this doesn't fabricate one —
/// it shows what the data honestly knows about them.
struct FriendProfileView: View {

    let friend: Friend

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var confirmingRemove = false
    @State private var toast: ToastMessage?

    private var sharedBoards: [Board] { store.boardsShared(with: friend.id) }
    private var recentActivity: [ActivityEvent] { store.activity(by: friend.id) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Space.unit * 4) {
                    ProfileHeader(
                        displayName: friend.name,
                        handle: friend.handle,
                        bio: friend.bio ?? "",
                        avatarSeed: friend.seed,
                        avatarImageName: friend.avatarImageName,
                        presence: friend.presence,
                        joinedAt: nil,
                        isWide: false
                    )

                    lastSeenLine

                    ProfileStatsRow(stats: stats)

                    BoardStrip(title: "Boards you share", boards: sharedBoards) { board in
                        store.openBoardID = board.id
                        store.tab = .board
                        dismiss()
                    }

                    inviteSection

                    if !recentActivity.isEmpty {
                        activitySection
                    }

                    removeButton
                }
                .padding(.horizontal, Space.unit * 3)
                .padding(.top, Space.unit * 3)
                .padding(.bottom, Space.unit * 6)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Palette.void)
            .navigationTitle(friend.firstName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .toast($toast)
        .presentationBackground(Palette.void)
        .confirmationDialog(
            "Remove \(friend.name)?",
            isPresented: $confirmingRemove,
            titleVisibility: .visible
        ) {
            Button("Remove friend", role: .destructive) {
                store.removeFriend(id: friend.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They'll be taken off \(sharedBoards.count) shared \(sharedBoards.count == 1 ? "board" : "boards"). Your memories stay.")
        }
    }

    // MARK: Pieces

    @ViewBuilder
    private var lastSeenLine: some View {
        if friend.presence != .online, let lastSeen = friend.lastSeen {
            Text("Last on \(RelativeTime.string(for: lastSeen))")
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.onSurfaceVariant)
        }
    }

    private var stats: [ProfileStatsRow.Stat] {
        [
            ProfileStatsRow.Stat(
                value: sharedBoards.count,
                label: "Shared boards",
                icon: "square.grid.2x2"
            ),
            ProfileStatsRow.Stat(
                value: store.memoriesShared(with: friend.id),
                label: "Memories",
                icon: "photo.on.rectangle.angled"
            ),
            ProfileStatsRow.Stat(
                value: recentActivity.count,
                label: "Recent acts",
                icon: "bolt"
            )
        ]
    }

    /// Invite them to a board they're not on yet. Two taps from the person,
    /// which is how anyone actually thinks about this ("add Leo to the trip
    /// board"), rather than opening the board and hunting for a share sheet.
    private var inviteSection: some View {
        let candidates = store.boards.filter { !$0.collaborators.contains(friend.id) }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Add to a board")
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.onSurfaceVariant)

            if candidates.isEmpty {
                Text("\(friend.firstName) is already on every board.")
                    .textStyle(TypeScale.bodyMD)
                    .foregroundStyle(Palette.onSurfaceVariant)
            } else {
                FlowRow(spacing: 8) {
                    ForEach(candidates) { board in
                        Button {
                            store.toggleCollaborator(friend.id, on: board.id)
                            toast = ToastMessage(text: "Added \(friend.firstName) to \(board.title)")
                        } label: {
                            Label(board.title, systemImage: "plus")
                                .textStyle(TypeScale.labelCaps)
                                .foregroundStyle(Palette.accent)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Capsule().fill(Palette.neon.opacity(0.14)))
                                .overlay(Capsule().strokeBorder(Palette.hairline, lineWidth: 1))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: Radius.widget)
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently")
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.onSurfaceVariant)

            ForEach(recentActivity) { event in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(Palette.accent)
                        .padding(.top, 7)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(event.verb) \(event.boardName)")
                            .textStyle(TypeScale.bodySM)
                            .foregroundStyle(Palette.onSurface)

                        Text(RelativeTime.string(for: event.date).uppercased())
                            .textStyle(TypeScale.labelTiny)
                            .foregroundStyle(Palette.onSurfaceVariant)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: Radius.widget)
    }

    private var removeButton: some View {
        Button(role: .destructive) {
            confirmingRemove = true
        } label: {
            Label("Remove friend", systemImage: "person.badge.minus")
                .textStyle(TypeScale.bodyMD)
                .fontWeight(.medium)
                .foregroundStyle(Palette.pinkAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(Palette.pink.opacity(0.10))
                )
        }
        .buttonStyle(PressableButtonStyle())
    }
}
