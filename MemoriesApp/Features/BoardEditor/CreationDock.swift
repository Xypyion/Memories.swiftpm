import SwiftUI

/// The floating creation dock.
///
/// It sits *above* the navigation bar rather than replacing it, because the two
/// answer different questions: the nav bar is "where am I", the dock is "what
/// can I put down". Collapsing them would make the primary creative action
/// compete with wayfinding.
struct CreationDock: View {

    var armedConnection: ConnectionStyle?

    let onAddPhoto: () -> Void
    let onAddNote: () -> Void
    let onAddSticker: () -> Void
    let onAdd: (QuickAdd) -> Void
    let onConnect: (ConnectionStyle) -> Void
    let onDraw: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            dockButton(icon: "photo", label: "Add photo", action: onAddPhoto)
            dockButton(icon: "text.alignleft", label: "Add note", action: onAddNote)

            primaryButton

            dockButton(icon: "seal", label: "Add sticker", action: onAddSticker)
            connectButton
            dockButton(icon: "pencil.tip.crop.circle", label: "Draw", action: onDraw)
        }
        .padding(8)
        .solidGlass(Capsule(style: .continuous))
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

    /// Twine and arrows are the same tool with two outputs, so they share one
    /// button. Tapping while armed disarms; otherwise it offers the choice.
    private var connectButton: some View {
        Menu {
            ForEach(ConnectionStyle.allCases, id: \.self) { style in
                Button {
                    onConnect(style)
                } label: {
                    Text(style.title)
                }
            }
            if armedConnection != nil {
                Divider()
                Button("Stop connecting") { onConnect(armedConnection ?? .twine) }
            }
        } label: {
            Image(systemName: "link")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(armedConnection != nil ? Palette.onNeon : Palette.onSurfaceVariant)
                .frame(width: 50, height: 50)
                .background {
                    if armedConnection != nil {
                        Circle().fill(Palette.neon)
                    }
                }
                .contentShape(Circle())
        }
        .accessibilityLabel("Connect two memories")
    }

    /// The neon key. Bordered in black so it reads as a thick vinyl button
    /// resting on the glass rather than a hole cut through it.
    private var primaryButton: some View {
        Menu {
            Section("Photos") {
                Button { onAdd(.mountedPrint) } label: { Text("Mounted print") }
                Button { onAdd(.polaroid) } label: { Text("Polaroid") }
            }
            Section("Paper") {
                ForEach(NoteColor.allCases, id: \.self) { color in
                    Button { onAdd(.note(color)) } label: { Text("\(color.displayName) note") }
                }
            }
            Section("Marks") {
                ForEach(DecorationKind.allCases, id: \.self) { kind in
                    Button { onAdd(.decoration(kind)) } label: { Text(kind.rawValue.capitalized) }
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Palette.onNeon)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Palette.neon))
                .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 2.5))
                .stickerShadow()
        }
        .padding(.horizontal, 4)
        .accessibilityLabel("Add to board")
    }
}

enum QuickAdd {
    case mountedPrint
    case polaroid
    case note(NoteColor)
    case sticker(StickerPayload)
    case decoration(DecorationKind)
}

/// A transient instruction banner. Used only for modal tools, where the user
/// needs to know the app is waiting on them.
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
        .solidGlass(Capsule(style: .continuous))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

/// The menu that appears where you long-press an empty part of the board.
struct CanvasPasteMenu: View {

    let hasPasteContent: Bool
    let onPaste: () -> Void
    let onAddNote: () -> Void
    let onAddPhoto: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row(title: hasPasteContent ? "Paste here" : "Nothing to paste",
                enabled: hasPasteContent,
                action: onPaste)

            Divider().overlay(Palette.hairline)

            row(title: "New note here", enabled: true, action: onAddNote)

            Divider().overlay(Palette.hairline)

            row(title: "Add photo here", enabled: true, action: onAddPhoto)
        }
        .frame(width: 210)
        .solidGlass(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func row(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            onDismiss()
        } label: {
            Text(title)
                .textStyle(TypeScale.bodyMD)
                .foregroundStyle(enabled ? Palette.onSurface : Palette.onSurfaceVariant.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
