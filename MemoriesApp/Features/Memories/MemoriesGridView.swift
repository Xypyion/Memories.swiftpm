import SwiftUI

/// Every memory in the app, flattened out of its boards.
///
/// The gallery answers "what collections do I have"; this answers "where is that
/// one photo". It keeps the tactile treatment — mounted prints at varying
/// rotation — but drops the free-form positioning, because a search surface
/// needs to be scannable in reading order.
struct MemoriesGridView: View {

    @EnvironmentObject private var store: AppStore

    @State private var filter: MemoryFilter = .all
    @State private var query = ""

    var body: some View {
        GeometryReader { geo in
            let columns = columnCount(for: geo.size.width)

            ScrollView {
                VStack(alignment: .leading, spacing: Space.unit * 4) {
                    header(isWide: geo.size.width > 820)
                    filters
                    searchField

                    if results.isEmpty {
                        emptyState
                    } else {
                        masonry(columnCount: columns, width: geo.size.width)
                    }
                }
                .padding(.horizontal, geo.size.width > 700 ? Space.canvasMargin : Space.unit * 2.5)
                .padding(.top, Space.unit * 6)
                .padding(.bottom, Space.dockClearance)
                .frame(maxWidth: 1440)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Palette.void)
        }
    }

    // MARK: Chrome

    private func header(isWide: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All memories")
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.neon)

            Text("Everything, everywhere")
                .textStyle(isWide ? TypeScale.displayLG : TypeScale.displayMD)
                .foregroundStyle(.white)

            Text("\(store.allMemories.count) memories across \(store.boards.count) boards.")
                .textStyle(TypeScale.bodyLG)
                .foregroundStyle(Palette.onSurfaceVariant)
        }
    }

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(MemoryFilter.allCases) { option in
                    FilterChip(title: option.title, isSelected: filter == option) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            filter = option
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.onSurfaceVariant)

            TextField("Search captions and boards", text: $query)
                .textFieldStyle(.plain)
                .textStyle(TypeScale.bodyMD)
                .foregroundStyle(Palette.onSurface)
                .autocorrectionDisabled()

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.onSurfaceVariant)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Palette.void, in: Capsule())
        .overlay {
            Capsule().strokeBorder(query.isEmpty ? Palette.hairline : Palette.neon.opacity(0.7), lineWidth: 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            DecorationView(kind: .sparkle, size: 52, color: Palette.onSurfaceVariant.opacity(0.4))

            Text("Nothing here yet")
                .textStyle(TypeScale.headline)
                .foregroundStyle(Palette.onSurface)

            Text(query.isEmpty
                 ? "Open a board and drop a photo onto the canvas."
                 : "No memory matches “\(query)”.")
                .textStyle(TypeScale.bodyMD)
                .foregroundStyle(Palette.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: Grid

    private func masonry(columnCount: Int, width: CGFloat) -> some View {
        let available = min(width, 1440) - (width > 700 ? Space.canvasMargin * 2 : Space.unit * 5)
        let tileWidth = (available - CGFloat(columnCount - 1) * Space.objectGap) / CGFloat(columnCount)
        let columns = distribute(results, into: columnCount)

        return HStack(alignment: .top, spacing: Space.objectGap) {
            ForEach(columns.indices, id: \.self) { columnIndex in
                VStack(spacing: Space.objectGap * 1.6) {
                    ForEach(columns[columnIndex]) { entry in
                        MemoryTile(
                            board: entry.board,
                            item: entry.item,
                            width: max(120, tileWidth - 8),
                            onOpen: {
                                store.openBoardID = entry.board.id
                                store.tab = .board
                            },
                            onToggleFavorite: {
                                store.toggleFavorite(boardID: entry.board.id, itemID: entry.item.id)
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func distribute(_ entries: [MemoryEntry], into count: Int) -> [[MemoryEntry]] {
        let width = max(1, count)
        var columns: [[MemoryEntry]] = Array(repeating: [], count: width)
        for (index, entry) in entries.enumerated() {
            columns[index % width].append(entry)
        }
        return columns
    }

    // MARK: Data

    private var results: [MemoryEntry] {
        store.allMemories
            .filter(matchesFilter)
            .filter(matchesQuery)
    }

    private func matchesFilter(_ entry: MemoryEntry) -> Bool {
        switch filter {
        case .all:
            return true
        case .favorites:
            return entry.item.kind.photo?.isFavorite == true
        case .shared:
            return !entry.board.collaborators.isEmpty
        case .polaroids:
            return entry.item.kind.isPolaroid
        }
    }

    private func matchesQuery(_ entry: MemoryEntry) -> Bool {
        guard !query.isEmpty else { return true }
        let caption = entry.item.kind.photo?.caption ?? ""
        return caption.localizedCaseInsensitiveContains(query)
            || entry.board.title.localizedCaseInsensitiveContains(query)
    }

    private func columnCount(for width: CGFloat) -> Int {
        if width > 1200 { return 4 }
        if width > 880 { return 3 }
        if width > 560 { return 2 }
        return 1
    }
}

enum MemoryFilter: String, CaseIterable, Identifiable {
    case all, favorites, shared, polaroids

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .favorites: "Favourites"
        case .shared: "Shared"
        case .polaroids: "Polaroids"
        }
    }
}

/// A single memory, still mounted on paper and still slightly crooked — the
/// tactile language survives the move from canvas to list.
struct MemoryTile: View {

    let board: Board
    let item: CanvasItem
    let width: CGFloat
    let onOpen: () -> Void
    let onToggleFavorite: () -> Void

    private var rotation: Double {
        // Stable per item, small enough to read as "hand-placed" rather than
        // broken.
        Double((item.seed % 9) - 4) * 0.7
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onOpen) {
                Group {
                    if case .polaroid(let payload) = item.kind {
                        PolaroidPhoto(payload: payload, seed: item.seed, width: width - 28)
                    } else {
                        MountedPhoto(
                            payload: item.kind.photo ?? PhotoPayload(),
                            seed: item.seed,
                            width: width - 24
                        )
                    }
                }
                .rotationEffect(.degrees(rotation))
            }
            .buttonStyle(LiftButtonStyle())

            HStack(spacing: 8) {
                Text(board.title)
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Button(action: onToggleFavorite) {
                    Image(systemName: (item.kind.photo?.isFavorite ?? false) ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle((item.kind.photo?.isFavorite ?? false) ? Palette.pink : Palette.onSurfaceVariant)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Favourite")
            }
            .padding(.horizontal, 6)
        }
        .frame(width: width)
    }
}
