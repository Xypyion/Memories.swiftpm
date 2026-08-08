import SwiftUI

/// Presence, stated once and quietly.
///
/// The previous indicator fired an expanding ring that scaled 2.4× and faded to
/// zero, on a loop, on every avatar in the friends list at once. A dozen of
/// those firing out of phase reads as a page of flashing lights — it competes
/// with the content it is annotating, which is exactly backwards for an ambient
/// signal.
///
/// This version keeps the dot completely still and breathes a soft halo behind
/// it: opacity only, no scale, slow, and never fully off, so at any instant it
/// still reads as a solid green dot. Peripheral vision registers "alive"; direct
/// vision registers "online" and moves on.
///
/// With reduced motion it becomes exactly what the brief suggested — a static
/// dot — with the halo held at a constant mid opacity so it loses no legibility.
struct OnlineStatus: View {

    enum Presence {
        case online
        case recentlyActive
        case offline

        var color: Color {
            switch self {
            case .online: Palette.neon
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

        var animates: Bool { self == .online }
    }

    let presence: Presence
    var size: CGFloat = 10
    /// The colour the dot is sitting on, so it reads as a cut-out.
    var surround: Color = Palette.void

    @Environment(\.motionPolicy) private var motion
    @State private var breathing = false

    private var haloOpacity: Double {
        guard presence.animates, !motion.isReduced else { return 0.34 }
        return breathing ? 0.10 : 0.42
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(presence.color)
                .opacity(haloOpacity)
                .frame(width: size * 2.05, height: size * 2.05)

            Circle()
                .fill(presence.color)
                .frame(width: size, height: size)
                .overlay {
                    Circle().strokeBorder(surround.opacity(0.85), lineWidth: size * 0.16)
                }
        }
        .frame(width: size * 2.05, height: size * 2.05)
        .onAppear {
            guard presence.animates, !motion.isReduced else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                breathing = true
            }
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
        .background(Capsule().fill(presence.color.opacity(0.12)))
        .accessibilityElement(children: .combine)
    }

    private var foreground: Color {
        switch presence {
        case .online: Palette.accent
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
