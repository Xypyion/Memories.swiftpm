import SwiftUI

/// The primary action. Neon fill, black label, and an inner top highlight so it
/// reads as a physical key rather than a coloured rectangle.
struct NeonButton: View {

    let title: String
    var icon: String? = nil
    var isCompact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .textStyle(TypeScale.sticker)
            }
            .foregroundStyle(Palette.onNeon)
            .padding(.horizontal, isCompact ? 16 : 24)
            .padding(.vertical, isCompact ? 8 : 11)
            .background {
                Capsule(style: .continuous)
                    .fill(Palette.neon)
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.55), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.5
                            )
                    }
            }
            .neonGlow(radius: 14, opacity: 0.30)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// A round glass icon button. Used everywhere a secondary action needs to sit
/// on top of content without stealing attention.
struct GlassIconButton: View {

    let icon: String
    var size: CGFloat = 44
    var isActive: Bool = false
    var badge: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(isActive ? Palette.neon : Palette.onSurfaceVariant)
                .frame(width: size, height: size)
                .liquidGlass(Circle(), tint: isActive ? 0.10 : 0.04, shadowRadius: 12)
                .overlay(alignment: .topTrailing) {
                    if badge {
                        Circle()
                            .fill(Palette.pink)
                            .frame(width: 9, height: 9)
                            .offset(x: 1, y: -1)
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Every interactive element in this app compresses slightly on touch. It is
/// the cheapest way to sell physicality, and it applies uniformly.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Section heading with the optional trailing action used across every screen.
struct SectionHeader<Trailing: View>: View {

    let title: String
    var accessory: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let accessory {
                Image(systemName: accessory)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.neon)
            }

            Text(title)
                .textStyle(TypeScale.headline)
                .foregroundStyle(Palette.onSurface)

            Spacer(minLength: 12)

            trailing()
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String, accessory: String? = nil) {
        self.init(title: title, accessory: accessory) { EmptyView() }
    }
}

/// Filter chips. The selected chip is the only neon thing in the row.
struct FilterChip: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(isSelected ? Palette.onNeon : Palette.onSurfaceVariant)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background {
                    if isSelected {
                        Capsule().fill(Palette.neon)
                    } else {
                        Capsule().fill(Color.white.opacity(0.06))
                    }
                }
                .overlay {
                    if !isSelected {
                        Capsule().strokeBorder(Palette.hairline, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
    }
}
