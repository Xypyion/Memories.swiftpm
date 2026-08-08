import SwiftUI

/// One object on the board, with direct manipulation attached.
///
/// Gesture design notes:
///
/// * **Drag is always live.** You should never have to select something before
///   you can move it — that is the whole premise of a physical board.
/// * **Pinch and rotate require selection.** If every item grabbed pinches, the
///   user could never zoom the canvas while their fingers happen to land on a
///   photo. Selection is the disambiguator.
/// * Drag translation is read in the *canvas* coordinate space, not the screen,
///   so a drag lands where the finger is at any zoom level without the caller
///   having to divide by the scale factor.
struct CanvasItemView: View {

    @Binding var item: CanvasItem

    var isSelected: Bool
    var isRopeAnchor: Bool
    var isRopeArmed: Bool

    let onSelect: () -> Void
    let onActivate: () -> Void
    let onCommit: () -> Void
    let onDelete: () -> Void

    @State private var dragOrigin: CGPoint?
    @State private var baseScale: CGFloat?
    @State private var baseRotation: Double?

    var body: some View {
        content
            .overlay { chrome }
            .overlay(alignment: .topTrailing) { deleteButton }
            .rotationEffect(.degrees(item.rotation))
            .scaleEffect(item.scale)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { onActivate() }
            .onTapGesture { onSelect() }
            .gesture(dragGesture)
            .simultaneousGesture(transformGesture, including: isSelected ? .all : .subviews)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch item.kind {
        case .photo(let payload):
            ZStack(alignment: .top) {
                MountedPhoto(payload: payload, seed: item.seed, width: item.width)
                TapeStrip(width: item.width * 0.3, rotation: -3)
                    .offset(y: -13)
            }

        case .polaroid(let payload):
            PolaroidPhoto(payload: payload, seed: item.seed, width: item.width)

        case .note(let payload):
            PaperNote(text: payload.text, color: payload.color, width: item.width)

        case .sticker(let payload):
            StickerBadge(text: payload.text, style: payload.style, rotation: 0, shape: .pill)
                .scaleEffect(item.width / 160)

        case .decoration(let kind):
            DecorationView(kind: kind, size: item.width, color: Palette.neon)
        }
    }

    // MARK: Selection chrome

    @ViewBuilder
    private var chrome: some View {
        if isSelected || isRopeAnchor {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(
                    isRopeAnchor ? Palette.pink : Palette.neon,
                    style: StrokeStyle(lineWidth: 2, dash: isRopeAnchor ? [6, 5] : [])
                )
                .padding(-8)
                .shadow(color: (isRopeAnchor ? Palette.pink : Palette.neon).opacity(0.5), radius: 10)
                .allowsHitTesting(false)
        } else if isRopeArmed {
            // While the twine tool is armed, every item advertises that it is a
            // valid target.
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Palette.pink.opacity(0.35), lineWidth: 1.5)
                .padding(-6)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var deleteButton: some View {
        if isSelected {
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.onPink)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Palette.pink))
                    .overlay(Circle().strokeBorder(Palette.void, lineWidth: 2))
            }
            .buttonStyle(PressableButtonStyle())
            .offset(x: 14, y: -14)
            .accessibilityLabel("Delete \(item.kind.label)")
        }
    }

    // MARK: Gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named(BoardEditorView.canvasSpace))
            .onChanged { value in
                if dragOrigin == nil {
                    dragOrigin = item.position
                    onSelect()
                }
                guard let origin = dragOrigin else { return }
                item.position = CGPoint(
                    x: origin.x + value.translation.width,
                    y: origin.y + value.translation.height
                )
            }
            .onEnded { _ in
                dragOrigin = nil
                onCommit()
            }
    }

    private var transformGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if baseScale == nil { baseScale = item.scale }
                let base = baseScale ?? 1
                item.scale = min(max(base * value.magnification, 0.35), 3.0)
            }
            .onEnded { _ in
                baseScale = nil
                onCommit()
            }
            .simultaneously(
                with: RotateGesture()
                    .onChanged { value in
                        if baseRotation == nil { baseRotation = item.rotation }
                        item.rotation = (baseRotation ?? 0) + value.rotation.degrees
                    }
                    .onEnded { _ in
                        baseRotation = nil
                        onCommit()
                    }
            )
    }
}
