import SwiftUI

/// A board's cover, built from the board's own contents.
///
/// There is no separate "cover image" field, deliberately. A board looks like
/// what is inside it, so the gallery stays truthful as the board changes and the
/// user never has to curate a thumbnail.
struct BoardCollage: View {

    let board: Board

    private var photographic: [CanvasItem] {
        board.items.filter { $0.kind.isPhotographic }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Palette.charcoal

                switch photographic.count {
                case 0:
                    emptyState

                case 1:
                    texture(for: photographic[0])
                        .frame(width: geo.size.width, height: geo.size.height)

                default:
                    collage(in: geo.size)
                }
            }
        }
    }

    private var emptyState: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.containerLow, Palette.charcoal],
                startPoint: .top,
                endPoint: .bottom
            )
            Image(systemName: "square.dashed")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Palette.onSurfaceVariant.opacity(0.35))
        }
    }

    /// Overlapping, rotated tiles — visual collision is a brand identifier, so
    /// the cover deliberately does not resolve into a clean grid.
    private func collage(in size: CGSize) -> some View {
        let tiles = Array(photographic.prefix(5))

        return ZStack {
            ForEach(tiles.indices, id: \.self) { index in
                let item = tiles[index]
                let layout = CollageLayout(index: index, total: tiles.count, canvas: size)

                texture(for: item)
                    .frame(width: layout.size.width, height: layout.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.eight, style: .continuous))
                    .rotationEffect(.degrees(layout.rotation))
                    .shadow(color: Palette.shadowHeavy, radius: 12, y: 6)
                    .offset(x: layout.offset.width, y: layout.offset.height)
                    .zIndex(Double(index))
            }
        }
    }

    /// Covers are decoration at a distance, never inspected closely, so they
    /// render at thumbnail detail — no grain pass per tile.
    private func texture(for item: CanvasItem) -> some View {
        MemoryImage(
            payload: item.kind.photo ?? PhotoPayload(),
            seed: item.seed,
            detail: .thumbnail
        )
    }
}

/// Deterministic scatter for collage tiles. Pure arithmetic so it never
/// reshuffles between renders.
private struct CollageLayout {

    let size: CGSize
    let offset: CGSize
    let rotation: Double

    init(index: Int, total: Int, canvas: CGSize) {
        let base = min(canvas.width, canvas.height)

        let scales: [CGFloat] = [0.92, 0.62, 0.54, 0.46, 0.40]
        let scale = scales[min(index, scales.count - 1)]

        size = CGSize(width: canvas.width * scale, height: base * scale * 1.15)

        let spread = canvas.width * 0.24
        let angles: [Double] = [-2, 5, -6, 8, -4]
        rotation = angles[min(index, angles.count - 1)]

        switch index {
        case 0: offset = CGSize(width: -canvas.width * 0.14, height: -base * 0.04)
        case 1: offset = CGSize(width: spread, height: base * 0.14)
        case 2: offset = CGSize(width: -spread * 1.1, height: base * 0.26)
        case 3: offset = CGSize(width: spread * 1.35, height: -base * 0.22)
        default: offset = CGSize(width: 0, height: -base * 0.30)
        }
    }
}

/// One tile in the gallery bento.
struct BoardCard: View {

    let board: Board
    let collaborators: [Friend]
    var height: CGFloat
    var isHero: Bool = false
    let onOpen: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onOpen) {
            ZStack(alignment: .bottomLeading) {
                BoardCollage(board: board)
                    // The collage is static per board: rasterise it once and
                    // scroll the bitmap, instead of re-compositing five layered,
                    // rotated, shadowed gradient stacks every frame.
                    .drawingGroup()
                    .opacity(0.75)

                scrim

                content
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            }
            .tactileShadow()
        }
        .buttonStyle(LiftButtonStyle())
        .accessibilityLabel("\(board.title), \(board.memoryCount) memories")
    }

    private var scrim: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.05),
                .black.opacity(0.55),
                .black.opacity(0.88)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                if !board.badge.isEmpty {
                    StickerBadge(text: board.badge, style: board.badgeStyle, rotation: -2)
                }

                Spacer(minLength: 12)

                if !collaborators.isEmpty {
                    FacePile(people: collaborators, size: 32, maxVisible: 3, borderColor: Palette.charcoal)
                }
            }

            Spacer(minLength: 24)

            // Fixed light text: this sits on the dark scrim painted over the
            // cover photo, which does not change with the theme.
            Text(board.title)
                .textStyle(isHero ? TypeScale.displayMD : TypeScale.headline)
                .foregroundStyle(Palette.onScrim)
                .lineLimit(2)
                // The card is a fixed-height tile in the bento, so a scaled-up
                // title has nowhere to go. Two lines, then shrink — a title that
                // gives back a fifth of its size still reads, where one clipped
                // by the tile's corner radius does not.
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)

            Text("\(board.memoryCount) memories · \(RelativeTime.updatedString(for: board.updatedAt))")
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.onScrimVariant)
                .padding(.top, 6)
        }
        .padding(Space.unit * 3)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Cards lift toward the viewer on press rather than dimming — consistent with
/// treating them as physical objects.
struct LiftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// The "create" affordance. Dashed, empty, and neon on hover — it reads as a
/// slot waiting to be filled rather than as another board.
struct CreateBoardCard: View {

    var height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 68, height: 68)
                    .background(Circle().fill(Palette.neon.opacity(0.16)))

                Text("Create Board")
                    .textStyle(TypeScale.headline)
                    .foregroundStyle(Palette.onSurface)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Palette.charcoal, in: RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
                    .strokeBorder(
                        Palette.hairlineBright,
                        style: StrokeStyle(lineWidth: 2, dash: [8, 8])
                    )
            }
        }
        .buttonStyle(LiftButtonStyle())
    }
}
