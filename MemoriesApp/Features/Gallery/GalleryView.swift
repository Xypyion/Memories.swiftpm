import SwiftUI

/// "Your Boards" — the entry point.
///
/// Laid out as an irregular bento rather than a uniform grid. A uniform grid
/// would say "these are files"; unequal tiles say "these are collections with
/// different weight", which is what a shelf of physical scrapbooks looks like.
struct GalleryView: View {

    @EnvironmentObject private var store: AppStore

    var body: some View {
        GeometryReader { geo in
            let columnCount = columnCount(for: geo.size.width)

            ScrollView {
                VStack(alignment: .leading, spacing: Space.unit * 5) {
                    header(isWide: geo.size.width > 820)

                    if let hero = store.boards.first {
                        BoardCard(
                            board: hero,
                            collaborators: store.collaborators(for: hero),
                            height: geo.size.width > 820 ? 400 : 300,
                            isHero: true,
                            onOpen: { open(hero) }
                        )
                    }

                    bento(columnCount: columnCount)
                }
                .padding(.horizontal, horizontalPadding(for: geo.size.width))
                .padding(.top, Space.unit * 6)
                .padding(.bottom, Space.dockClearance)
                .frame(maxWidth: 1440)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Palette.void)
        }
    }

    // MARK: Header

    private func header(isWide: Bool) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Memories")
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.neon)

                Text("Your Boards")
                    .textStyle(isWide ? TypeScale.displayLG : TypeScale.displayMD)
                    .foregroundStyle(.white)

                Text("Collections of chaotic moments.")
                    .textStyle(TypeScale.bodyLG)
                    .foregroundStyle(Palette.onSurfaceVariant)
            }

            Spacer(minLength: 24)

            if isWide {
                ZStack {
                    GlowBlob(color: Palette.pink, size: 150, opacity: 0.30)
                    DecorationView(kind: .sparkle, size: 74, color: Palette.pink)
                        .rotationEffect(.degrees(12))
                }
                .frame(width: 150, height: 150)
                .accessibilityHidden(true)
            }
        }
    }

    // MARK: Bento

    private func bento(columnCount: Int) -> some View {
        let columns = distribute(tiles: tiles, into: columnCount)

        return HStack(alignment: .top, spacing: Space.objectGap) {
            ForEach(columns.indices, id: \.self) { columnIndex in
                VStack(spacing: Space.objectGap) {
                    ForEach(columns[columnIndex]) { tile in
                        view(for: tile)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }

    @ViewBuilder
    private func view(for tile: GalleryTile) -> some View {
        switch tile {
        case .board(let board):
            BoardCard(
                board: board,
                collaborators: store.collaborators(for: board),
                height: height(for: board),
                onOpen: { open(board) }
            )

        case .create:
            CreateBoardCard(height: 300) {
                let id = store.createBoard()
                withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
                    store.openBoardID = id
                }
            }
        }
    }

    // MARK: Layout maths

    private var tiles: [GalleryTile] {
        // The first board is promoted to the full-width hero above the bento.
        store.boards.dropFirst().map(GalleryTile.board) + [.create]
    }

    private func height(for board: Board) -> CGFloat {
        switch board.tileWeight {
        case .hero: 400
        case .tall: 460
        case .standard: 300
        }
    }

    private func height(for tile: GalleryTile) -> CGFloat {
        switch tile {
        case .board(let board): height(for: board)
        case .create: 300
        }
    }

    /// Greedy shortest-column packing. Produces the uneven, editorial rhythm
    /// the design calls for without any hand-tuned per-count special cases.
    private func distribute(tiles: [GalleryTile], into columnCount: Int) -> [[GalleryTile]] {
        var columns: [[GalleryTile]] = Array(repeating: [], count: max(1, columnCount))
        var running: [CGFloat] = Array(repeating: 0, count: max(1, columnCount))

        for tile in tiles {
            var shortest = 0
            for index in running.indices where running[index] < running[shortest] {
                shortest = index
            }
            columns[shortest].append(tile)
            running[shortest] += height(for: tile) + Space.objectGap
        }

        return columns
    }

    private func columnCount(for width: CGFloat) -> Int {
        if width > 1100 { return 3 }
        if width > 700 { return 2 }
        return 1
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width > 700 ? Space.canvasMargin : Space.unit * 2.5
    }

    private func open(_ board: Board) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            store.openBoardID = board.id
        }
    }
}

enum GalleryTile: Identifiable {

    case board(Board)
    case create

    var id: String {
        switch self {
        case .board(let board): board.id.uuidString
        case .create: "create"
        }
    }
}
