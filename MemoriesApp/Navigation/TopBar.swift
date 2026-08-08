import SwiftUI

/// The floating top bar: who you are on the left, Settings on the right.
///
/// Same Liquid Glass language as the dock, and the same reason for floating —
/// content bleeds underneath it rather than being pushed down by it. Scroll
/// views pay for it with `Space.topBarClearance` instead of a layout inset.
///
/// It hides inside the board editor, which has its own header. Two floating bars
/// stacked on one another would be noise, and the canvas needs the room.
struct TopBar: View {

    let account: UserAccount?
    let onOpenProfile: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if let account {
                Button(action: onOpenProfile) {
                    HStack(spacing: 10) {
                        AvatarView(
                            name: account.displayName,
                            seed: account.avatarSeed,
                            size: 32,
                            ring: .neon,
                            imageName: account.avatarImageName
                        )

                        Text(account.displayName)
                            .textStyle(TypeScale.labelCaps)
                            .foregroundStyle(Palette.onSurface)
                            .lineLimit(1)
                    }
                    .padding(.leading, 6)
                    .padding(.trailing, 14)
                    .padding(.vertical, 6)
                    .contentShape(Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Your profile")
            }

            Spacer(minLength: 0)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .frame(width: 40, height: 40)
                    .contentShape(Circle())
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .liquidGlass(Capsule(style: .continuous), tint: 0.05, strokeOpacity: 0.18, shadowRadius: 22)
        .padding(.horizontal, Space.canvasMargin)
        .padding(.top, Space.unit)
    }
}
