import PhotosUI
import SwiftUI
import UIKit

/// The Living Canvas.
///
/// Everything here serves one idea: the board is a *surface*, not a document.
/// Items are absolutely positioned in the board's own 2200 × 1500 coordinate
/// space, they overlap, they rotate, and nothing snaps to a grid. The viewport
/// pans and zooms over that space the way a hand moves over a table.
struct BoardEditorView: View {

    let boardID: UUID
    let onClose: () -> Void

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var account: AccountStore
    @Environment(\.motionPolicy) private var motion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Named so item drags can report translation in board coordinates rather
    /// than screen coordinates.
    static let canvasSpace = "board.canvas"

    private let canvasSize = CGSize(width: 2200, height: 1500)

    // Viewport
    @State private var zoom: CGFloat = 0.6
    @State private var committedZoom: CGFloat = 0.6
    @State private var pan: CGSize = .zero
    @State private var committedPan: CGSize = .zero

    // Interaction
    @State private var selection: UUID?
    @State private var armedConnection: ConnectionStyle?
    @State private var connectionAnchor: UUID?
    @State private var inspecting: EditingTarget?
    @State private var pasteAnchor: PasteAnchor?

    /// The tie that just happened: the rope that should spring taut, and the two
    /// items that should pulse. Cleared shortly after, so the moment is a moment.
    @State private var justTiedRope: UUID?
    @State private var justTiedItems: Set<UUID> = []

    /// Object-level undo. `Board` is a value type, so a step backwards is just a
    /// copy kept from before the edit — no command objects, no inverse
    /// operations to get wrong.
    ///
    /// Snapshots are taken **only on commit**: a grab, an insert, a delete, a
    /// tie or a cut. Never per drag frame, which would push 120 copies a second
    /// and undo one pixel at a time.
    @State private var undoStack: [Board] = []

    private static let undoLimit = 20

    // Drawing. `nil` means the pen is away.
    @State private var drawing: DrawingTool?
    @State private var liveStroke: DrawnStroke?

    // Sheets and prompts
    @State private var showsPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var pendingPhotoPoint: CGPoint?
    @State private var showsStickerPicker = false
    @State private var showsShare = false
    @State private var showsRename = false
    @State private var draftTitle = ""
    @State private var confirmingDelete = false
    @State private var headerWidth: CGFloat = 0
    @State private var toast: ToastMessage?

    /// `@State`, not `@StateObject`: this view owns the object's lifetime but
    /// must not subscribe to it, or every gesture frame would re-render the
    /// whole canvas. See `CanvasLiveState`.
    @State private var live = CanvasLiveState()

    private var board: Board {
        store.board(id: boardID) ?? .placeholder
    }

    private var boardBinding: Binding<Board> {
        store.binding(forBoard: boardID)
    }

    /// iPad portrait is still a `.regular` size class, so laying the header out
    /// by size class left it overflowing in portrait — which is what made the
    /// Share button look wrong. Measured width is the honest signal.
    ///
    /// An accessibility text size counts as narrow for the same reason a
    /// portrait iPad does: the row has run out of room. Reusing this one flag
    /// means large text gets the layout that was already built and tested for
    /// the cramped case — icon-only Share, no presence cluster, tighter gaps —
    /// instead of a second set of rules that only large text ever exercises.
    private var isNarrowHeader: Bool {
        dynamicTypeSize.isAccessibilitySize || (headerWidth > 0 && headerWidth < 720)
    }

    private var isDrawing: Bool { drawing != nil }

    /// Mutate this board in the store, in place. Used instead of writing through
    /// `boardBinding.wrappedValue` so every structural edit goes through one
    /// well-defined path that also stamps `updatedAt`.
    private func withBoard(_ mutate: (inout Board) -> Void) {
        guard let index = store.boards.firstIndex(where: { $0.id == boardID }) else { return }
        mutate(&store.boards[index])
        store.boards[index].updatedAt = Date()
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .top) {
            Palette.board.ignoresSafeArea()

            canvas

            header

            VStack {
                Spacer()

                if let armedConnection, !isDrawing {
                    ToolHintBanner(
                        text: connectionAnchor == nil
                            ? "Tap a memory to start the \(armedConnection.title.lowercased())"
                            : "Tap another memory to finish"
                    )
                    .padding(.bottom, 12)
                }

                if isDrawing {
                    DrawingToolbar(
                        tool: Binding(
                            get: { drawing ?? DrawingTool() },
                            set: { drawing = $0 }
                        ),
                        canUndo: !board.strokes.isEmpty,
                        onUndo: { withBoard { if !$0.strokes.isEmpty { $0.strokes.removeLast() } } },
                        onClear: { withBoard { $0.strokes.removeAll() } },
                        onDone: { drawing = nil }
                    )
                    .dockClearance()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    CreationDock(
                        armedConnection: armedConnection,
                        onAddPhoto: { pendingPhotoPoint = nil; showsPhotoPicker = true },
                        onAddNote: { add(.note(.blush)) },
                        onAddSticker: { showsStickerPicker = true },
                        onAdd: { add($0) },
                        onConnect: toggleConnection,
                        onDraw: { startDrawing() }
                    )
                    .dockClearance()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(motion.animation(.spring(response: 0.35, dampingFraction: 0.85)), value: isDrawing)
        .animation(motion.animation(.spring(response: 0.3, dampingFraction: 0.8)), value: undoStack.isEmpty)
        .toast($toast)
        .photosPicker(isPresented: $showsPhotoPicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: photoPickerItem) { _, newValue in
            guard let newValue else { return }
            Task { await importPhoto(newValue) }
        }
        .sheet(isPresented: $showsStickerPicker) {
            StickerPicker { sticker in
                add(.sticker(sticker))
            }
        }
        .sheet(item: $inspecting) { target in
            if let index = board.items.firstIndex(where: { $0.id == target.id }) {
                ItemInspector(item: boardBinding.items[index]) {
                    store.touch(boardID: boardID)
                }
            }
        }
        .sheet(isPresented: $showsShare) {
            ShareBoardSheet(board: board, collaborators: store.collaborators(for: board))
        }
        .alert("Rename board", isPresented: $showsRename) {
            TextField("Board name", text: $draftTitle)
            Button("Save") {
                let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                withBoard { $0.title = trimmed }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Delete “\(board.title)”?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete board", role: .destructive) {
                store.deleteBoard(id: boardID)
                onClose()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \(board.memoryCount) memories and any imported photos.")
        }
    }

    // MARK: Canvas

    private var canvas: some View {
        GeometryReader { geo in
            ZStack {
                canvasContent
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .coordinateSpace(.named(BoardEditorView.canvasSpace))
                    .scaleEffect(zoom)
                    .offset(pan)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(motion.animation(.easeOut(duration: 0.15))) {
                    selection = nil
                    connectionAnchor = nil
                    pasteAnchor = nil
                }
            }
            .gesture(canvasGesture(in: geo.size))
            .simultaneousGesture(longPressMenuGesture(in: geo.size))
            .overlay {
                if let pasteAnchor {
                    pasteMenu(pasteAnchor)
                }
            }
            .clipped()
        }
        .ignoresSafeArea()
    }

    private var canvasContent: some View {
        ZStack {
            CanvasBackdrop(style: preferences.canvasGrid)

            // Connections are their own observing view so that a drag redraws a
            // couple of shapes rather than the entire canvas.
            RopeLayer(
                ropes: board.ropes,
                positions: itemPositions,
                canvasSize: canvasSize,
                justTiedID: justTiedRope,
                live: live
            )

            DrawingLayer(strokes: board.strokes, liveStroke: liveStroke)

            ForEach(boardBinding.items) { $item in
                CanvasItemView(
                    item: $item,
                    isSelected: selection == item.id,
                    isConnectionAnchor: connectionAnchor == item.id,
                    isConnectionArmed: armedConnection != nil,
                    isJustTied: justTiedItems.contains(item.id),
                    snapsToGrid: preferences.snapToGrid,
                    live: live,
                    onSelect: { handleTap(on: item.id) },
                    onActivate: { inspecting = EditingTarget(id: item.id) },
                    onCommit: { store.touch(boardID: boardID) },
                    onDelete: { delete(itemID: item.id) },
                    onGrab: { snapshotForUndo() },
                    onDragEnded: { account.noteCoachDrag() }
                )
                .position(item.position)
                // The selected item floats above the stack. Driven by
                // `selection` (local `@State`) rather than by drag state, so it
                // costs one re-render per selection, not one per frame.
                .zIndex(selection == item.id ? item.zIndex + 5_000 : item.zIndex)
            }
            // While the pen is out, the objects step back so a stroke crossing a
            // photo draws on the board instead of dragging the photo.
            .allowsHitTesting(!isDrawing)
        }
    }

    /// Snapshot of every item's stored position, handed to the rope layer so it
    /// never has to search `board.items` while a gesture is running.
    private var itemPositions: [UUID: CGPoint] {
        Dictionary(uniqueKeysWithValues: board.items.map { ($0.id, $0.position) })
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: isNarrowHeader ? 10 : 16) {
            GlassIconButton(icon: "chevron.left", size: 44, action: onClose)
                .accessibilityLabel("Back to boards")

            VStack(alignment: .leading, spacing: 3) {
                Button {
                    draftTitle = board.title
                    showsRename = true
                } label: {
                    HStack(spacing: 6) {
                        Text(board.title)
                            .textStyle(TypeScale.headline)
                            .foregroundStyle(Palette.accent)
                            .lineLimit(1)
                            // Give back a fifth of the size before resorting to
                            // an ellipsis — the board's name is the one thing in
                            // this row the reader actually needs.
                            .minimumScaleFactor(0.8)
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Palette.accent.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)

                Text("\(board.memoryCount) memories · \(Int(zoom * 100))%")
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            if !isNarrowHeader {
                presenceCluster
                    .padding(.leading, 12)
            }

            Spacer(minLength: 8)

            actions
        }
        .padding(.horizontal, isNarrowHeader ? Space.unit * 2 : Space.canvasMargin)
        .padding(.vertical, 12)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Palette.void.opacity(0.55))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Palette.hairline).frame(height: 1)
                }
                .ignoresSafeArea(edges: .top)
        }
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { headerWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, width in headerWidth = width }
            }
        }
    }

    private var presenceCluster: some View {
        HStack(spacing: 10) {
            FacePile(
                people: store.collaborators(for: board),
                size: 36,
                maxVisible: 3,
                borderColor: Palette.void
            )

            if store.collaborators(for: board).contains(where: { $0.isActive }) {
                HStack(spacing: 7) {
                    OnlineStatus(presence: .online, size: 7, surround: .clear)
                    // "(demo)" because there is no networking: this presence is
                    // seeded, and the most visible simulated thing in the app
                    // should be the one that admits it first.
                    Text("ON THE BOARD (DEMO)")
                        .textStyle(TypeScale.labelTiny)
                        .foregroundStyle(Palette.accent)
                        // Holds its width rather than being squeezed to "ON"
                        // and clipped by the capsule around it.
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Palette.neon.opacity(0.12)))
            }
        }
    }

    private var actions: some View {
        HStack(spacing: isNarrowHeader ? 6 : 10) {
            // Only present once there is something to take back, so a fresh
            // board isn't carrying a permanently dead control.
            if !undoStack.isEmpty {
                GlassIconButton(icon: "arrow.uturn.backward", size: 40, action: undo)
                    .accessibilityLabel("Undo")
                    .transition(.scale.combined(with: .opacity))
            }

            if !isNarrowHeader {
                GlassIconButton(icon: "arrow.counterclockwise", size: 40, action: resetView)
                    .accessibilityLabel("Reset view")
            }

            Menu {
                Button {
                    draftTitle = board.title
                    showsRename = true
                } label: {
                    Label("Rename board", systemImage: "pencil")
                }

                Picker("Grid", selection: $preferences.canvasGrid) {
                    ForEach(CanvasGridStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }

                Toggle(isOn: $preferences.snapToGrid) {
                    Label("Snap to grid", systemImage: "square.grid.2x2")
                }

                if isNarrowHeader {
                    Button {
                        resetView()
                    } label: {
                        Label("Reset view", systemImage: "arrow.counterclockwise")
                    }
                }

                if !board.ropes.isEmpty {
                    Button {
                        withAnimation { withBoard { $0.ropes.removeAll() } }
                    } label: {
                        Label("Remove all connections", systemImage: "link.badge.plus")
                    }
                }

                if !board.strokes.isEmpty {
                    Button {
                        withAnimation { withBoard { $0.strokes.removeAll() } }
                    } label: {
                        Label("Clear drawing", systemImage: "eraser")
                    }
                }

                Divider()

                Button(role: .destructive) {
                    confirmingDelete = true
                } label: {
                    Label("Delete board", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .frame(width: 44, height: 44)
                    .liquidGlass(Circle(), tint: 0.04)
            }
            .accessibilityLabel("Board options")

            // In portrait the labelled pill crowded the title off the row. An
            // icon button carries the same action in a third of the width.
            if isNarrowHeader {
                Button {
                    showsShare = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.onNeon)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Palette.neon))
                        .contentShape(Circle())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Share board")
            } else {
                NeonButton(title: "Share", icon: "square.and.arrow.up") {
                    showsShare = true
                }
            }
        }
    }

    // MARK: Viewport gestures

    private func canvasGesture(in size: CGSize) -> some Gesture {
        if isDrawing {
            return AnyGesture(drawGesture(in: size).map { _ in () })
        }
        return AnyGesture(
            panGesture.simultaneously(with: zoomGesture(in: size)).map { _ in () }
        )
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                pan = CGSize(
                    width: committedPan.width + value.translation.width,
                    height: committedPan.height + value.translation.height
                )
            }
            .onEnded { _ in committedPan = pan }
    }

    /// Zoom about the point between the fingers.
    ///
    /// `scaleEffect` scales about its anchor — the view's centre by default —
    /// which is why pinching used to drag the board towards the middle of the
    /// screen no matter where you put your fingers. Rather than moving the
    /// anchor (which would fight the pan offset), this keeps the anchor at the
    /// centre and *counter-pans* so the board point under the pinch stays under
    /// the pinch.
    ///
    /// With `f` as the focal point measured from the screen centre:
    ///     pan′ = f − (f − pan) · (zoom′ / zoom)
    private func zoomGesture(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newZoom = min(max(committedZoom * value.magnification, 0.28), 2.2)
                let ratio = newZoom / committedZoom

                let focal = CGPoint(
                    x: value.startAnchor.x * size.width - size.width / 2,
                    y: value.startAnchor.y * size.height - size.height / 2
                )

                zoom = newZoom
                pan = CGSize(
                    width: focal.x - (focal.x - committedPan.width) * ratio,
                    height: focal.y - (focal.y - committedPan.height) * ratio
                )
            }
            .onEnded { _ in
                committedZoom = zoom
                committedPan = pan
            }
    }

    /// Ink lands under the finger at any zoom or pan.
    ///
    /// This used to read `value.location` in the named canvas space. That space
    /// is declared *underneath* `.scaleEffect(zoom)` and `.offset(pan)`, and
    /// converting a point down through a `scaleEffect` does not reliably undo
    /// the scale — so the stroke drifted further from the finger the further you
    /// drew from the centre of the board, and drifted more the further you were
    /// zoomed out.
    ///
    /// Reading the raw touch in `.local` and inverting the transform by hand is
    /// arithmetic we control. It is the same conversion the long-press menu
    /// already uses to place things where you pressed.
    private func drawGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard let tool = drawing else { return }

                let point = canvasPoint(fromScreen: value.location, in: size)

                if tool.mode == .eraser {
                    erase(at: point)
                    return
                }

                if liveStroke == nil {
                    liveStroke = DrawnStroke(
                        points: [canvasPoint(fromScreen: value.startLocation, in: size)],
                        colorHex: tool.colorHex,
                        width: tool.width,
                        isHighlighter: tool.mode == .highlighter
                    )
                }
                liveStroke?.points.append(point)
            }
            .onEnded { _ in
                // One store write for the whole stroke, exactly as with drags.
                if let stroke = liveStroke, stroke.points.count > 1 {
                    withBoard { $0.strokes.append(stroke) }
                }
                liveStroke = nil
            }
    }

    /// Long-press an empty part of the board for a menu at that spot.
    private func longPressMenuGesture(in size: CGSize) -> some Gesture {
        LongPressGesture(minimumDuration: 0.45)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onChanged { value in
                guard !isDrawing, pasteAnchor == nil else { return }
                guard case .second(true, let drag?) = value else { return }

                let screen = drag.startLocation
                pasteAnchor = PasteAnchor(
                    screenPoint: screen,
                    canvasPoint: canvasPoint(fromScreen: screen, in: size)
                )
            }
    }

    /// Screen point → board coordinates. The inverse of the transform the canvas
    /// applies: `screen = centre + (board − boardCentre) · zoom + pan`.
    private func canvasPoint(fromScreen screen: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: canvasSize.width / 2 + (screen.x - size.width / 2 - pan.width) / zoom,
            y: canvasSize.height / 2 + (screen.y - size.height / 2 - pan.height) / zoom
        )
    }

    @ViewBuilder
    private func pasteMenu(_ anchor: PasteAnchor) -> some View {
        CanvasPasteMenu(
            hasPasteContent: UIPasteboard.general.hasImages || UIPasteboard.general.hasStrings,
            onPaste: { paste(at: anchor.canvasPoint) },
            onAddNote: { insert(.note(NotePayload(text: "", color: .blush)), width: 240, at: anchor.canvasPoint, openInspector: true) },
            onAddPhoto: {
                pendingPhotoPoint = anchor.canvasPoint
                showsPhotoPicker = true
            },
            onDismiss: { pasteAnchor = nil }
        )
        .position(anchor.screenPoint)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    // MARK: Undo

    /// Call immediately *before* a committed object mutation.
    private func snapshotForUndo() {
        guard let current = store.board(id: boardID) else { return }
        undoStack.append(current)
        if undoStack.count > BoardEditorView.undoLimit {
            undoStack.removeFirst()
        }
    }

    private func undo() {
        guard
            let previous = undoStack.popLast(),
            let index = store.boards.firstIndex(where: { $0.id == boardID })
        else { return }

        Haptics.place()

        withAnimation(motion.animation(.spring(response: 0.4, dampingFraction: 0.8))) {
            // Objects and connections only. Strokes have their own undo in the
            // drawing toolbar, and restoring them here would let one Undo button
            // silently erase work the other one owns.
            store.boards[index].items = previous.items
            store.boards[index].ropes = previous.ropes
            store.boards[index].updatedAt = Date()
            selection = nil
            connectionAnchor = nil
        }
    }

    // MARK: Actions

    private func resetView() {
        withAnimation(motion.animation(.spring(response: 0.4, dampingFraction: 0.8))) {
            zoom = 0.6
            committedZoom = 0.6
            pan = .zero
            committedPan = .zero
        }
    }

    private func startDrawing() {
        selection = nil
        armedConnection = nil
        connectionAnchor = nil
        drawing = DrawingTool()
    }

    private func handleTap(on itemID: UUID) {
        guard armedConnection != nil else {
            selection = itemID
            return
        }

        guard let anchor = connectionAnchor else {
            connectionAnchor = itemID
            Haptics.select()
            return
        }

        guard anchor != itemID else {
            connectionAnchor = nil
            return
        }

        withAnimation(motion.animation(.spring(response: 0.45, dampingFraction: 0.7))) {
            connectOrDisconnect(anchor, itemID)
        }
        connectionAnchor = nil
    }

    /// Tapping a pair that is already joined cuts the connection. One gesture,
    /// both directions — no separate delete affordance for a decorative object.
    private func connectOrDisconnect(_ a: UUID, _ b: UUID) {
        let style = armedConnection ?? .twine
        var tiedRope: RopeConnection?

        snapshotForUndo()

        withBoard { board in
            let existing = board.ropes.firstIndex {
                ($0.a == a && $0.b == b) || ($0.a == b && $0.b == a)
            }

            if let existing {
                board.ropes.remove(at: existing)
                Haptics.cut()
            } else {
                let rope = RopeConnection(a: a, b: b, style: style)
                board.ropes.append(rope)
                tiedRope = rope
                Haptics.tie()
            }
        }

        guard let tiedRope else { return }

        justTiedRope = tiedRope.id
        justTiedItems = [a, b]
        account.noteCoachTie()

        // The tie is a moment, not a state: the rope keeps its taut shape but
        // the two items stop glowing shortly after.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 650_000_000)
            justTiedRope = nil
            withAnimation(motion.animation(.easeOut(duration: 0.25))) {
                justTiedItems = []
            }
        }
    }

    private func toggleConnection(_ style: ConnectionStyle) {
        withAnimation(motion.animation(.spring(response: 0.35, dampingFraction: 0.8))) {
            if armedConnection == style {
                armedConnection = nil
            } else {
                armedConnection = style
                selection = nil
            }
            connectionAnchor = nil
        }
    }

    private func erase(at point: CGPoint) {
        let threshold: CGFloat = 26
        withBoard { board in
            board.strokes.removeAll { stroke in
                stroke.points.contains { hypot($0.x - point.x, $0.y - point.y) < threshold }
            }
        }
    }

    private func delete(itemID: UUID) {
        // The imported JPEG is deliberately left on disk. Undo restores the
        // item, and an item pointing at a file we already deleted would come
        // back as a blank frame — a visibly broken undo is worse than an
        // orphaned file. Deleting the whole board still purges its images.
        Haptics.delete()
        snapshotForUndo()

        withAnimation(motion.animation(.spring(response: 0.35, dampingFraction: 0.75))) {
            withBoard { board in
                board.items.removeAll { $0.id == itemID }
                board.ropes.removeAll { $0.a == itemID || $0.b == itemID }
            }
            selection = nil
        }
    }

    private func add(_ quickAdd: QuickAdd) {
        switch quickAdd {
        case .mountedPrint:
            insert(.photo(PhotoPayload(caption: "New memory", aspect: 0.8)), width: 260)
        case .polaroid:
            insert(.polaroid(PhotoPayload(caption: "…", aspect: 1)), width: 240)
        case .note(let color):
            insert(.note(NotePayload(text: "", color: color)), width: 240, openInspector: true)
        case .sticker(let payload):
            insert(.sticker(payload), width: 160)
        case .decoration(let kind):
            insert(.decoration(kind), width: 110)
        }
    }

    private func insert(
        _ kind: CanvasItemKind,
        width: CGFloat,
        at point: CGPoint? = nil,
        openInspector: Bool = false
    ) {
        guard let boardIndex = store.boards.firstIndex(where: { $0.id == boardID }) else { return }

        snapshotForUndo()

        var rng = SeededGenerator(seed: store.boards[boardIndex].items.count &* 7919 &+ Int(zoom * 1000))
        let center = point ?? viewportCenter
        let jitter: CGFloat = point == nil ? 80 : 0

        let dropPoint = CGPoint(
            x: center.x + (jitter == 0 ? 0 : CGFloat.random(in: -jitter ... jitter, using: &rng)),
            y: center.y + (jitter == 0 ? 0 : CGFloat.random(in: -jitter ... jitter, using: &rng))
        )

        // In snap mode the scatter is the wrong instinct: a new object should
        // land squarely on the grid and sit straight, or the board stays messy
        // no matter how carefully you place things afterwards.
        var item = CanvasItem(
            kind: kind,
            position: preferences.snapToGrid ? CanvasGrid.snap(dropPoint) : dropPoint,
            rotation: preferences.snapToGrid ? 0 : Double.random(in: -5 ... 5, using: &rng),
            zIndex: store.boards[boardIndex].topZIndex,
            seed: Int.random(in: 0 ..< 100_000, using: &rng),
            width: width
        )
        item.createdAt = Date()
        // New memories inherit the board's prevailing topic, so the Memories tab
        // groups them sensibly without the user having to file anything.
        item.topic = store.boards[boardIndex].dominantTopic

        withAnimation(motion.animation(.spring(response: 0.42, dampingFraction: 0.68))) {
            store.boards[boardIndex].items.append(item)
            store.boards[boardIndex].updatedAt = Date()
            selection = item.id
        }

        if openInspector {
            inspecting = EditingTarget(id: item.id)
        }
    }

    /// Centre of the visible viewport, expressed in board coordinates.
    private var viewportCenter: CGPoint {
        CGPoint(
            x: canvasSize.width / 2 - pan.width / zoom,
            y: canvasSize.height / 2 - pan.height / zoom
        )
    }

    private func paste(at point: CGPoint) {
        let pasteboard = UIPasteboard.general

        if pasteboard.hasImages, let image = pasteboard.image,
           let data = image.jpegData(compressionQuality: 0.9),
           let name = ImageStore.save(data: data) {
            var payload = PhotoPayload(imageName: name, caption: "", aspect: 0.8)
            if image.size.height > 0 {
                payload.aspect = image.size.width / image.size.height
            }
            insert(.photo(payload), width: 280, at: point)
            toast = ToastMessage(text: "Photo pasted")
            return
        }

        if pasteboard.hasStrings,
           let text = pasteboard.string?.trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            insert(.note(NotePayload(text: text, color: .blush)), width: 260, at: point)
            toast = ToastMessage(text: "Text pasted")
            return
        }

        toast = ToastMessage(text: "Nothing on the clipboard", tone: .warning)
    }

    @MainActor
    private func importPhoto(_ pickerItem: PhotosPickerItem) async {
        defer {
            photoPickerItem = nil
            pendingPhotoPoint = nil
        }

        guard
            let data = try? await pickerItem.loadTransferable(type: Data.self),
            let name = ImageStore.save(data: data)
        else { return }

        var payload = PhotoPayload(imageName: name, caption: "", aspect: 0.8)
        if let image = ImageStore.image(named: name), image.size.height > 0 {
            payload.aspect = image.size.width / image.size.height
        }

        insert(.photo(payload), width: 280, at: pendingPhotoPoint)
    }
}

/// Wrapper so a `UUID` can drive `.sheet(item:)`.
struct EditingTarget: Identifiable {
    let id: UUID
}

/// Where a long-press happened, in both spaces: screen for placing the menu,
/// board for placing whatever the menu creates.
struct PasteAnchor: Identifiable {
    let id = UUID()
    var screenPoint: CGPoint
    var canvasPoint: CGPoint
}

/// The board surface itself.
struct CanvasBackdrop: View {

    var style: CanvasGridStyle

    var body: some View {
        Canvas { context, size in
            switch style {
            case .none:
                break

            case .dots:
                let step = CanvasGrid.step
                var y: CGFloat = 0
                while y < size.height {
                    var x: CGFloat = 0
                    while x < size.width {
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                            with: .color(Palette.onSurface.opacity(0.16))
                        )
                        x += step
                    }
                    y += step
                }

            case .lines:
                let step = CanvasGrid.step
                var path = Path()
                var x: CGFloat = 0
                while x < size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += step
                }
                var y: CGFloat = 0
                while y < size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += step
                }
                context.stroke(path, with: .color(Palette.onSurface.opacity(0.10)), lineWidth: 1)
            }
        }
        .background(Palette.board)
        .allowsHitTesting(false)
    }
}
