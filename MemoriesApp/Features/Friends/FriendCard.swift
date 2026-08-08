import SwiftUI

/// A friend, in a row. Tapping it opens them.
///
/// Replaces the decorative avatar grid, where the whole list looked interactive
/// and none of it was. Every friend in the app is now reachable through this one
/// component, so there is exactly one place that decides what tapping a person
/// does.
struct FriendCard: View {

    let friend: Friend
    var sharedBoardCount: Int = 0
    var style: Style = .row
    let onOpen: () -> Void

    enum Style {
        /// Full-width row with name, handle and presence.
        case row
        /// Compact avatar-and-first-name tile for dense grids.
        case tile
    }

    var body: some View {
        Button(action: onOpen) {
            switch style {
            case .row: rowBody
            case .tile: tileBody
            }
        }
        .buttonStyle(style == .row ? AnyButtonStyle(LiftButtonStyle()) : AnyButtonStyle(PressableButtonStyle()))
        .accessibilityLabel("\(friend.name), \(friend.presence.label)")
        .accessibilityHint("Opens their profile")
    }

    private var rowBody: some View {
        HStack(spacing: 14) {
            avatar(size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(friend.name)
                    .textStyle(TypeScale.bodyMD)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.onSurface)
                    .lineLimit(1)

                Text(sharedBoardCount > 0
                     ? "\(friend.handle) · \(sharedBoardCount) shared"
                     : friend.handle)
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if friend.presence != .offline {
                PresenceBadge(presence: friend.presence, compact: true)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.onSurfaceVariant.opacity(0.6))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private var tileBody: some View {
        VStack(spacing: 8) {
            avatar(size: 62)

            Text(friend.firstName)
                .textStyle(TypeScale.labelTiny)
                .foregroundStyle(friend.isActive ? Palette.onSurface : Palette.onSurfaceVariant)
                .lineLimit(1)
        }
        .frame(width: 78)
        .contentShape(Rectangle())
    }

    private func avatar(size: CGFloat) -> some View {
        AvatarView(
            name: friend.name,
            seed: friend.seed,
            size: size,
            ring: friend.ringStyle,
            imageName: friend.avatarImageName
        )
        .opacity(friend.isActive ? 1 : 0.55)
        .saturation(friend.isActive ? 1 : 0.25)
        .overlay(alignment: .bottomTrailing) {
            if friend.presence == .online {
                OnlineStatus(presence: .online, size: size * 0.2, surround: Palette.void)
                    .offset(x: 2, y: 2)
            }
        }
    }
}

/// Type-erased button style, so `FriendCard` can pick its press behaviour by
/// style without duplicating its body.
struct AnyButtonStyle: ButtonStyle {

    private let makeBodyClosure: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        makeBodyClosure = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        makeBodyClosure(configuration)
    }
}

/// A searchable list of friends. Used in the hub and reusable anywhere a person
/// needs picking.
struct FriendsList: View {

    let friends: [Friend]
    let sharedCount: (Friend) -> Int
    let onOpen: (Friend) -> Void

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(friends) { friend in
                FriendCard(
                    friend: friend,
                    sharedBoardCount: sharedCount(friend),
                    style: .row,
                    onOpen: { onOpen(friend) }
                )
                .glassPanel(cornerRadius: Radius.card)
            }
        }
    }
}
