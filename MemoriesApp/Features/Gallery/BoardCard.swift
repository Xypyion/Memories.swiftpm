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
            Palette.containerLow
            Image(systemName: "square.dashed")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Palette.onSurfaceVariant.opacity(0.4))
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
            // A gallery label, not a caption burned into the picture.
            //
            // The title used to sit on the cover under a gradient scrim that
            // reached 88% black, with the cover itself dimmed to 75% underneath
            // it. Between them the artwork was barely visible — every board in
            // the gallery came out as the same grey haze. Now the picture runs
            // at full strength and the words sit below it on their own solid
            // plate, which is both how a print is actually labelled and the only
            // arrangement where the title's contrast doesn't depend on whatever
            // the cover happens to look like.
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    BoardCollage(board: board)
                        // The collage is static per board: rasterise it once and
                        // scroll the bitmap, instead of re-compositing five
                        // layered, rotated, shadowed stacks every frame.
                        .drawingGroup()

                    marks
                }
                .frame(maxHeight: .infinity)
                .clipped()

                caption
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

    /// What sits *on* the picture: the board's badge and who else is on it.
    /// Both carry their own backing, so neither needs the picture dimmed.
    private var marks: some View {
        HStack(alignment: .top) {
            if !board.badge.isEmpty {
                StickerBadge(text: board.badge, style: board.badgeStyle, rotation: -2)
            }

            Spacer(minLength: 12)

            if !collaborators.isEmpty {
                FacePile(people: collaborators, size: 32, maxVisible: 3, borderColor: Palette.charcoal)
            }
        }
        .padding(Space.unit * 2)
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(board.title)
                .textStyle(isHero ? TypeScale.displayMD : TypeScale.headline)
                .foregroundStyle(Palette.onSurface)
                .lineLimit(2)
                // The card is a fixed-height tile in the bento, so a scaled-up
                // title has nowhere to go. Two lines, then shrink — a title that
                // gives back a fifth of its size still reads, where one clipped
                // by the tile's corner radius does not.
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)

            Text("\(board.memoryCount) memories · \(RelativeTime.updatedString(for: board.updatedAt))")
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.onSurfaceVariant)
        }
        .padding(.horizontal, Space.unit * 2.5)
        .padding(.vertical, Space.unit * 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.charcoal)
    }
}

/// Cards lift toward the viewer on press rather than dimming — consistent with
/// treating them as physical objects.
struct LiftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Lift(isPressed: configuration.isPressed, label: configuration.label)
    }

    /// Split out for the same reason as `PressableButtonStyle.Pressable`: a
    /// `ButtonStyle` cannot observe the environment, and a view can.
    private struct Lift: View {

        let isPressed: Bool
        let label: ButtonStyleConfiguration.Label

        @Environment(\.motionPolicy) private var motion

        var body: some View {
            label
                .scaleEffect(isPressed ? 0.985 : 1)
                .offset(y: isPressed ? 2 : 0)
                .animation(motion.animation(.spring(response: 0.3, dampingFraction: 0.7)), value: isPressed)
        }
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
