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
///
/// Performance: an in-flight gesture mutates **local `@State` only** and is
/// committed to the model once, on release. See `CanvasLiveState` for why.
struct CanvasItemView: View {

    @Binding var item: CanvasItem

    var isSelected: Bool
    var isConnectionAnchor: Bool
    var isConnectionArmed: Bool

    /// Held as a plain reference, not `@ObservedObject` — this view drives it
    /// but must not re-render from it.
    let live: CanvasLiveState

    let onSelect: () -> Void
    let onActivate: () -> Void
    let onCommit: () -> Void
    let onDelete: () -> Void

    // In-flight gesture state. None of this touches the store.
    @State private var dragTranslation: CGSize = .zero
    @State private var isDragging = false
    @State private var pinchScale: CGFloat = 1
    @State private var twistDegrees: Double = 0

    private var renderedScale: CGFloat {
        min(max(item.scale * pinchScale, 0.35), 3.0)
    }

    var body: some View {
        content
            .overlay { chrome }
            .overlay(alignment: .topTrailing) { deleteButton }
            .rotationEffect(.degrees(item.rotation + twistDegrees))
            .scaleEffect(renderedScale)
            .offset(dragTranslation)
            // Lifts the object off the board while it is being moved. Stacking
            // order is raised by the parent via `selection` — a zIndex applied
            // here would do nothing, since this view has no siblings.
            .shadow(color: Palette.shadowHeavy, radius: isDragging ? 26 : 0, y: isDragging ? 18 : 0)
            .contentShape(Rectangle())
            // One tap recogniser, not two.
            //
            // A `count: 2` gesture alongside a `count: 1` gesture forces every
            // single tap to wait out the double-tap window before it can fire —
            // which is exactly the delay you feel when selecting something. Now
            // the first tap selects instantly, and tapping an already-selected
            // object opens it. Same two actions, no waiting for either.
            .onTapGesture { isSelected ? onActivate() : onSelect() }
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
            DecorationView(kind: kind, size: item.width, color: Palette.accent)
        }
    }

    // MARK: Selection chrome

    @ViewBuilder
    private var chrome: some View {
        if isSelected || isConnectionAnchor {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(
                    isConnectionAnchor ? Palette.pink : Palette.neon,
                    style: StrokeStyle(lineWidth: 2, dash: isConnectionAnchor ? [6, 5] : [])
                )
                .padding(-8)
                .allowsHitTesting(false)
        } else if isConnectionArmed {
            // While the connect tool is armed, every item advertises that it is
            // a valid target.
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Palette.pink.opacity(0.35), lineWidth: 1.5)
                .padding(-6)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var deleteButton: some View {
        if isSelected, !isConnectionArmed {
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.onPink)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Palette.pink))
                    .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 2))
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
                if !isDragging {
                    isDragging = true
                    live.begin(item.id)
                    onSelect()
                }
                dragTranslation = value.translation
                live.update(value.translation)
            }
            .onEnded { value in
                // The single store write for the whole gesture.
                item.position = CGPoint(
                    x: item.position.x + value.translation.width,
                    y: item.position.y + value.translation.height
                )
                dragTranslation = .zero
                isDragging = false
                live.end()
                onCommit()
            }
    }

    private var transformGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                pinchScale = value.magnification
            }
            .onEnded { _ in
                item.scale = renderedScale
                pinchScale = 1
                onCommit()
            }
            .simultaneously(
                with: RotateGesture()
                    .onChanged { value in
                        twistDegrees = value.rotation.degrees
                    }
                    .onEnded { _ in
                        item.rotation += twistDegrees
                        twistDegrees = 0
                        onCommit()
                    }
            )
    }
}
