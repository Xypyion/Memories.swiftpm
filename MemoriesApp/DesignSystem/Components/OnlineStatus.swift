import SwiftUI

/// Presence, stated once and then left alone.
///
/// This started as an expanding, fading ring on a loop. Then it became a
/// breathing halo. Both were wrong for the same reason: presence is a *fact*,
/// not an event, and animating a fact makes a dozen friend avatars flicker at
/// once while you are trying to read past them.
///
/// It is now a plain dot. No pulse, no halo, no glow. The ring around it is a
/// cut-out in the surface behind, so it stays crisp on a photo or a card.
struct OnlineStatus: View {

    enum Presence {
        case online
        case recentlyActive
        case offline

        var color: Color {
            switch self {
            case .online: Color(hex: 0x3ED66B)
            case .recentlyActive: Palette.pink
            case .offline: Palette.outline
            }
        }

        var label: String {
            switch self {
            case .online: "Online"
            case .recentlyActive: "Recently active"
            case .offline: "Offline"
            }
        }
    }

    let presence: Presence
    var size: CGFloat = 10
    /// The colour the dot is sitting on, so it reads as a cut-out.
    var surround: Color = Palette.void

    var body: some View {
        Circle()
            .fill(presence.color)
            .frame(width: size, height: size)
            .overlay {
                Circle().strokeBorder(surround, lineWidth: size * 0.22)
            }
            .accessibilityLabel(presence.label)
    }
}

/// The dot plus its word, for places with room to be explicit.
struct PresenceBadge: View {

    let presence: OnlineStatus.Presence
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 7) {
            OnlineStatus(presence: presence, size: compact ? 7 : 8, surround: .clear)

            Text(presence.label.uppercased())
                .textStyle(compact ? TypeScale.labelTiny : TypeScale.labelCaps)
                .foregroundStyle(foreground)
        }
        .padding(.horizontal, compact ? 8 : 11)
        .padding(.vertical, compact ? 4 : 6)
        .background(Capsule().fill(presence.color.opacity(0.14)))
        .accessibilityElement(children: .combine)
    }

    private var foreground: Color {
        switch presence {
        case .online: Color.adaptive(light: 0x1E7A3C, dark: 0x3ED66B)
        case .recentlyActive: Palette.pinkAccent
        case .offline: Palette.onSurfaceVariant
        }
    }
}

extension Friend {
    /// One place that decides what a friend's ring and dot mean, so the friends
    /// list, the board header and the share sheet can never disagree.
    var presence: OnlineStatus.Presence {
        if isActive { return .online }
        return ringStyle == .pink ? .recentlyActive : .offline
    }
}
