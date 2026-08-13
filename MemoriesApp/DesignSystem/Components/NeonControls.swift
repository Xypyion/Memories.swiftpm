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
                        .symbolStyle(TypeScale.sticker, size: 14, weight: .bold)
                }
                Text(title)
                    .textStyle(TypeScale.sticker)
                    // A button label is a name, not prose. Breaking "Share" into
                    // "Sh / are" to fit a squeezed row is never the right answer:
                    // the label holds its width and the row gives ground.
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(Palette.onNeon)
            .padding(.horizontal, isCompact ? 16 : 24)
            .padding(.vertical, isCompact ? 8 : 11)
            .background {
                Capsule(style: .continuous)
                    .fill(Palette.neon)
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5)
                    }
            }
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
                .foregroundStyle(isActive ? Palette.accent : Palette.onSurfaceVariant)
                .frame(width: size, height: size)
                .liquidGlass(Circle(), tint: isActive ? 0.10 : 0.04)
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

extension View {
    /// Guarantees a control the platform's 44pt minimum touch area without
    /// changing what is drawn.
    ///
    /// The distinction matters on this canvas: a delete badge on a photo has to
    /// stay small or it covers the photo, but a small *target* on a surface
    /// where fingers are already imprecise is how you delete the wrong memory.
    /// The artwork keeps its size and the reachable area grows around it.
    func minimumHitArea(_ side: CGFloat = 44) -> some View {
        frame(minWidth: side, minHeight: side)
            .contentShape(Rectangle())
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
///
/// No leading icon. A glyph beside a heading that already says "Active now"
/// tells the reader nothing the words did not, and a page full of them turns
/// every heading into a row of decoration to scan past.
struct SectionHeader<Trailing: View>: View {

    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .textStyle(TypeScale.headline)
                .foregroundStyle(Palette.onSurface)

            Spacer(minLength: 12)

            trailing()
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title: title) { EmptyView() }
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
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
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
