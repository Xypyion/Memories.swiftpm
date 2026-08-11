import SwiftUI

/// The two floating top controls: your profile on the left, Settings on the
/// right.
///
/// They used to be one connected bar spanning the width of the screen, which
/// made them read as a header — a piece of structure the content had to live
/// under. Split apart they read as what they are: two controls resting on top of
/// the page, with the content running full-width behind and between them.
///
/// They retract when you scroll down and come back at the top. Chrome that is
/// only useful when you are *not* reading should not be present while you are.
struct FloatingProfilePill: View {

    let account: UserAccount?
    let action: () -> Void

    var body: some View {
        if let account {
            Button(action: action) {
                HStack(spacing: 9) {
                    AvatarView(
                        name: account.displayName,
                        seed: account.avatarSeed,
                        size: 30,
                        ring: .neon,
                        imageName: account.avatarImageName
                    )

                    Text(account.displayName)
                        .textStyle(TypeScale.labelCaps)
                        .foregroundStyle(Palette.onSurface)
                        .lineLimit(1)
                }
                .padding(.leading, 5)
                .padding(.trailing, 14)
                .padding(.vertical, 5)
                .solidGlass(Capsule(style: .continuous))
                .contentShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Your profile")
        }
    }
}

struct FloatingSettingsButton: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Palette.onSurfaceVariant)
                .frame(width: 42, height: 42)
                .solidGlass(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Settings")
    }
}

/// Positions the pair and handles the hide-on-scroll behaviour.
struct FloatingTopControls: View {

    let account: UserAccount?
    let isVisible: Bool
    let onOpenProfile: () -> Void
    let onOpenSettings: () -> Void

    @Environment(\.motionPolicy) private var motion

    var body: some View {
        HStack(alignment: .top) {
            FloatingProfilePill(account: account, action: onOpenProfile)
            Spacer(minLength: 12)
            FloatingSettingsButton(action: onOpenSettings)
        }
        .padding(.horizontal, Space.canvasMargin)
        .padding(.top, Space.unit)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -80)
        // Not just hidden — unhittable, so a retracted control can never eat a
        // tap meant for the content underneath it.
        .allowsHitTesting(isVisible)
        .animation(motion.animation(.spring(response: 0.34, dampingFraction: 0.9)), value: isVisible)
    }
}
