import PhotosUI
import SwiftUI

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
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.motionPolicy) private var motion

    /// `@State`, not `@StateObject`: this view owns the object's lifetime but
    /// must not subscribe to it, or every gesture frame would re-render the
    /// whole canvas. See `CanvasLiveState`.
    @State private var live = CanvasLiveState()

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
    @State private var isRopeArmed = false
    @State private var ropeAnchor: UUID?
    @State private var inspecting: EditingTarget?

    // Sheets and prompts
    @State private var showsPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showsShare = false
    @State private var showsRename = false
    @State private var draftTitle = ""
    @State private var confirmingDelete = false

    private var board: Board {
        store.board(id: boardID) ?? .placeholder
    }

    private var boardBinding: Binding<Board> {
        store.binding(forBoard: boardID)
    }

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

                if isRopeArmed {
                    ToolHintBanner(
                        text: ropeAnchor == nil
                            ? "Tap a memory to start the twine"
                            : "Tap another memory to tie it off"
                    )
                    .padding(.bottom, 12)
                }

                CreationDock(
                    isRopeArmed: isRopeArmed,
                    onAddPhoto: { showsPhotoPicker = true },
                    onAddNote: { add(.note(.blush)) },
                    onAddSticker: { add(.sticker(.neon)) },
                    onAdd: { add($0) },
                    onToggleRope: toggleRopeTool
                )
                .padding(.bottom, Space.dockClearance)
            }
        }
        .photosPicker(isPresented: $showsPhotoPicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: photoPickerItem) { _, newValue in
            guard let newValue else { return }
            Task { await importPhoto(newValue) }
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
                withAnimation(.easeOut(duration: 0.15)) {
                    selection = nil
                    if isRopeArmed { ropeAnchor = nil }
                }
            }
            .gesture(panGesture.simultaneously(with: zoomGesture))
            .clipped()
        }
        .ignoresSafeArea()
    }

    private var canvasContent: some View {
        ZStack {
            CanvasBackdrop()

            // Ropes are their own observing view so that a drag redraws two
            // shapes rather than the entire canvas.
            RopeLayer(
                ropes: board.ropes,
                positions: itemPositions,
                canvasSize: canvasSize,
                live: live
            )

            ForEach(boardBinding.items) { $item in
                CanvasItemView(
                    item: $item,
                    isSelected: selection == item.id,
                    isRopeAnchor: ropeAnchor == item.id,
                    isRopeArmed: isRopeArmed,
                    live: live,
                    onSelect: { handleTap(on: item.id) },
                    onActivate: { inspecting = EditingTarget(id: item.id) },
                    onCommit: { store.touch(boardID: boardID) },
                    onDelete: { delete(itemID: item.id) }
                )
                .position(item.position)
                // The selected item floats above the stack. Driven by
                // `selection` (local `@State`) rather than by drag state, so it
                // costs one re-render per selection, not one per frame.
                .zIndex(selection == item.id ? item.zIndex + 5_000 : item.zIndex)
            }

            if showsPresenceCursor, let ghost = activeCollaborator {
                PresenceCursor(name: ghost.name, canvasSize: canvasSize)
                    .zIndex(9_999)
            }
        }
    }

    /// Snapshot of every item's stored position, handed to the rope layer so it
    /// never has to search `board.items` while a gesture is running.
    private var itemPositions: [UUID: CGPoint] {
        Dictionary(uniqueKeysWithValues: board.items.map { ($0.id, $0.position) })
    }

    private var activeCollaborator: Friend? {
        store.collaborators(for: board).first { $0.isActive }
    }

    /// The demo cursor is an animation with a repeating timer behind it. It is
    /// off when the user asked for less motion, and off when they switched the
    /// demo off — never left running invisibly.
    private var showsPresenceCursor: Bool {
        preferences.showsPresenceDemo && !motion.isReduced
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 16) {
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
                            .foregroundStyle(Palette.neon)
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Palette.neon.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)

                Text("\(board.memoryCount) memories · \(Int(zoom * 100))%")
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.onSurfaceVariant)
            }

            if sizeClass == .regular {
                presenceCluster
                    .padding(.leading, 12)
            }

            Spacer(minLength: 8)

            actions
        }
        .padding(.horizontal, Space.canvasMargin)
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
    }

    private var presenceCluster: some View {
        HStack(spacing: 10) {
            FacePile(
                people: store.collaborators(for: board),
                size: 36,
                maxVisible: 3,
                borderColor: Palette.void
            )

            if activeCollaborator != nil {
                HStack(spacing: 7) {
                    OnlineStatus(presence: .online, size: 7, surround: .clear)
                    Text("ON THE BOARD")
                        .textStyle(TypeScale.labelTiny)
                        .foregroundStyle(Palette.accent)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Palette.neon.opacity(0.12)))
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            if sizeClass == .regular {
                GlassIconButton(icon: "arrow.counterclockwise", size: 40) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        zoom = 0.6
                        committedZoom = 0.6
                        pan = .zero
                        committedPan = .zero
                    }
                }
                .accessibilityLabel("Reset view")
            }

            Menu {
                Button {
                    draftTitle = board.title
                    showsRename = true
                } label: {
                    Label("Rename board", systemImage: "pencil")
                }

                Toggle(isOn: $preferences.showsPresenceDemo) {
                    Label("Show live presence (demo)", systemImage: "dot.radiowaves.left.and.right")
                }

                if !board.ropes.isEmpty {
                    Button {
                        withAnimation { withBoard { $0.ropes.removeAll() } }
                    } label: {
                        Label("Remove all twine", systemImage: "link.badge.plus")
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
                    .frame(width: 40, height: 40)
                    .liquidGlass(Circle(), tint: 0.04, shadowRadius: 12)
            }
            .accessibilityLabel("Board options")

            NeonButton(title: "Share", icon: "square.and.arrow.up", isCompact: sizeClass == .compact) {
                showsShare = true
            }
        }
    }

    // MARK: Viewport gestures

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

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = min(max(committedZoom * value.magnification, 0.28), 2.2)
            }
            .onEnded { _ in committedZoom = zoom }
    }

    // MARK: Actions

    private func handleTap(on itemID: UUID) {
        guard isRopeArmed else {
            selection = itemID
            return
        }

        guard let anchor = ropeAnchor else {
            ropeAnchor = itemID
            return
        }

        guard anchor != itemID else {
            ropeAnchor = nil
            return
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            tieOrUntie(anchor, itemID)
        }
        ropeAnchor = nil
    }

    /// Tapping a pair that is already tied cuts the twine. One gesture, both
    /// directions — no separate delete affordance for a decorative object.
    private func tieOrUntie(_ a: UUID, _ b: UUID) {
        withBoard { board in
            let existing = board.ropes.firstIndex {
                ($0.a == a && $0.b == b) || ($0.a == b && $0.b == a)
            }

            if let existing {
                board.ropes.remove(at: existing)
            } else {
                board.ropes.append(RopeConnection(a: a, b: b))
            }
        }
    }

    private func toggleRopeTool() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isRopeArmed.toggle()
            ropeAnchor = nil
            if isRopeArmed { selection = nil }
        }
    }

    private func delete(itemID: UUID) {
        if let item = board.items.first(where: { $0.id == itemID }),
           let name = item.kind.photo?.imageName {
            ImageStore.delete(named: name)
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
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
            insert(.note(NotePayload(text: "", color: color)), width: 240)
        case .sticker(let style):
            insert(.sticker(StickerPayload(text: "Vibes only", style: style)), width: 160)
        case .decoration(let kind):
            insert(.decoration(kind), width: 110)
        }
    }

    private func insert(_ kind: CanvasItemKind, width: CGFloat) {
        guard let boardIndex = store.boards.firstIndex(where: { $0.id == boardID }) else { return }

        var rng = SeededGenerator(seed: store.boards[boardIndex].items.count &* 7919 &+ Int(zoom * 1000))
        let center = viewportCenter

        let item = CanvasItem(
            kind: kind,
            position: CGPoint(
                x: center.x + CGFloat.random(in: -80 ... 80, using: &rng),
                y: center.y + CGFloat.random(in: -70 ... 70, using: &rng)
            ),
            rotation: Double.random(in: -5 ... 5, using: &rng),
            zIndex: store.boards[boardIndex].topZIndex,
            seed: Int.random(in: 0 ..< 100_000, using: &rng),
            width: width
        )

        withAnimation(.spring(response: 0.42, dampingFraction: 0.68)) {
            store.boards[boardIndex].items.append(item)
            store.boards[boardIndex].updatedAt = Date()
            selection = item.id
        }

        // A brand-new empty note is useless until it has words in it, so open
        // the inspector straight away.
        if case .note = kind {
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

    @MainActor
    private func importPhoto(_ pickerItem: PhotosPickerItem) async {
        defer { photoPickerItem = nil }

        guard
            let data = try? await pickerItem.loadTransferable(type: Data.self),
            let name = ImageStore.save(data: data)
        else { return }

        var payload = PhotoPayload(imageName: name, caption: "", aspect: 0.8)
        if let image = ImageStore.image(named: name), image.size.height > 0 {
            payload.aspect = image.size.width / image.size.height
        }

        insert(.photo(payload), width: 280)
    }
}

/// Wrapper so a `UUID` can drive `.sheet(item:)`.
struct EditingTarget: Identifiable {
    let id: UUID
}

/// The board surface itself: a faint dot grid that gives the canvas a sense of
/// extent without imposing a layout.
struct CanvasBackdrop: View {

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 64
            let dot: CGFloat = 2

            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: dot, height: dot)),
                        with: .color(.white.opacity(0.055))
                    )
                    x += step
                }
                y += step
            }
        }
        .background(Palette.board)
        .allowsHitTesting(false)
    }
}

/// A collaborator's cursor drifting across the board.
///
/// This is a *demonstration* of the presence layer, driven locally — the app has
/// no networking. It can be switched off from the board menu, and the menu item
/// says so.
struct PresenceCursor: View {

    let name: String
    let canvasSize: CGSize

    @State private var target: CGPoint = .zero

    private let timer = Timer.publish(every: 3.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "cursorarrow")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Palette.pink)
                .shadow(color: .black.opacity(0.5), radius: 3, y: 2)

            Text(name.split(separator: " ").first.map(String.init) ?? name)
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.onPink)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Palette.pink))
                .offset(y: 10)
        }
        .fixedSize()
        .position(target)
        .allowsHitTesting(false)
        .onAppear(perform: move)
        .onReceive(timer) { _ in move() }
    }

    private func move() {
        var rng = SeededGenerator(seed: Int(target.x + target.y) &+ 31)
        let next = CGPoint(
            x: CGFloat.random(in: canvasSize.width * 0.2 ... canvasSize.width * 0.8, using: &rng),
            y: CGFloat.random(in: canvasSize.height * 0.2 ... canvasSize.height * 0.8, using: &rng)
        )
        withAnimation(.easeInOut(duration: 2.6)) {
            target = next
        }
    }
}
