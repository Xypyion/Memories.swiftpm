import SwiftUI

/// The floating creation dock.
///
/// It sits *above* the navigation bar rather than replacing it, because the two
/// answer different questions: the nav bar is "where am I", the dock is "what
/// can I put down". Collapsing them would make the primary creative action
/// compete with wayfinding.
struct CreationDock: View {

    var isRopeArmed: Bool

    let onAddPhoto: () -> Void
    let onAddNote: () -> Void
    let onAddSticker: () -> Void
    let onAdd: (QuickAdd) -> Void
    let onToggleRope: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            dockButton(icon: "photo", label: "Add photo", action: onAddPhoto)
            dockButton(icon: "text.alignleft", label: "Add note", action: onAddNote)

            primaryButton

            dockButton(icon: "sparkles", label: "Add sticker", action: onAddSticker)

            dockButton(
                icon: "link",
                label: "Connect with twine",
                isActive: isRopeArmed,
                action: onToggleRope
            )
        }
        .padding(8)
        .liquidGlass(Capsule(style: .continuous), tint: 0.04, strokeOpacity: 0.16, shadowRadius: 34)
    }

    private func dockButton(
        icon: String,
        label: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isActive ? Palette.onNeon : Palette.onSurfaceVariant)
                .frame(width: 50, height: 50)
                .background {
                    if isActive {
                        Circle().fill(Palette.neon)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(label)
    }

    /// The neon key. Bordered in black so it reads as a thick vinyl button
    /// resting on the glass rather than a hole cut through it.
    private var primaryButton: some View {
        Menu {
            Section("Photos") {
                Button { onAdd(.mountedPrint) } label: {
                    Label("Mounted print", systemImage: "photo")
                }
                Button { onAdd(.polaroid) } label: {
                    Label("Polaroid", systemImage: "camera")
                }
            }
            Section("Paper") {
                ForEach(NoteColor.allCases, id: \.self) { color in
                    Button { onAdd(.note(color)) } label: {
                        Label("\(color.displayName) note", systemImage: "note.text")
                    }
                }
            }
            Section("Marks") {
                ForEach(DecorationKind.allCases, id: \.self) { kind in
                    Button { onAdd(.decoration(kind)) } label: {
                        Label(kind.rawValue.capitalized, systemImage: "scribble.variable")
                    }
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Palette.onNeon)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Palette.neon))
                .overlay(Circle().strokeBorder(Palette.void, lineWidth: 2.5))
                .stickerShadow()
                .neonGlow(radius: 18, opacity: 0.4)
        }
        .padding(.horizontal, 4)
        .accessibilityLabel("Add to board")
    }
}

enum QuickAdd {
    case mountedPrint
    case polaroid
    case note(NoteColor)
    case sticker(StickerStyle)
    case decoration(DecorationKind)
}

/// A transient instruction banner. Used only for modal tools (twine), where the
/// user needs to know the app is waiting on them.
struct ToolHintBanner: View {

    let text: String
    var accent: Color = Palette.pink

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)

            Text(text)
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.onSurface)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .liquidGlass(Capsule(style: .continuous), tint: 0.06, shadowRadius: 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
