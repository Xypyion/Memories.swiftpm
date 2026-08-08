import SwiftUI

/// A single memory, still mounted on paper and still slightly crooked — the
/// tactile language survives the move from canvas to list.
struct MemoryTile: View {

    let entry: MemoryEntry
    let width: CGFloat
    var showsBoardName: Bool = true
    let onOpen: () -> Void
    let onToggleFavorite: () -> Void

    private var isFavorite: Bool {
        entry.item.kind.photo?.isFavorite ?? false
    }

    /// Stable per item, small enough to read as "hand-placed" rather than
    /// broken.
    private var rotation: Double {
        Double((entry.item.seed % 9) - 4) * 0.7
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onOpen) {
                Group {
                    if entry.item.kind.isPolaroid, let payload = entry.item.kind.photo {
                        PolaroidPhoto(payload: payload, seed: entry.item.seed, width: width - 28)
                    } else {
                        MountedPhoto(
                            payload: entry.item.kind.photo ?? PhotoPayload(),
                            seed: entry.item.seed,
                            width: width - 24
                        )
                    }
                }
                .rotationEffect(.degrees(rotation))
            }
            .buttonStyle(LiftButtonStyle())
            .accessibilityLabel(entry.caption.isEmpty ? "Untitled memory" : entry.caption)
            .accessibilityHint("Opens \(entry.board.title)")

            HStack(spacing: 8) {
                if showsBoardName {
                    Text(entry.board.title)
                        .textStyle(TypeScale.labelCaps)
                        .foregroundStyle(Palette.onSurfaceVariant)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isFavorite ? Palette.pink : Palette.onSurfaceVariant)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(isFavorite ? "Remove from favourites" : "Add to favourites")
            }
            .padding(.horizontal, 6)
        }
        .frame(width: width)
    }
}

/// Column-balanced layout for memory tiles.
///
/// Shared by both organisation schemes so a day section and a topic section are
/// laid out identically, and so a third scheme gets the same behaviour without
/// re-implementing it.
struct MemoryMasonry: View {

    let entries: [MemoryEntry]
    let availableWidth: CGFloat
    let onOpen: (MemoryEntry) -> Void
    let onToggleFavorite: (MemoryEntry) -> Void

    private var columnCount: Int {
        if availableWidth > 1200 { return 4 }
        if availableWidth > 880 { return 3 }
        if availableWidth > 560 { return 2 }
        return 1
    }

    private var tileWidth: CGFloat {
        let gaps = CGFloat(columnCount - 1) * Space.objectGap
        return max(140, (availableWidth - gaps) / CGFloat(columnCount) - 8)
    }

    private var columns: [[MemoryEntry]] {
        var result: [[MemoryEntry]] = Array(repeating: [], count: columnCount)
        for (index, entry) in entries.enumerated() {
            result[index % columnCount].append(entry)
        }
        return result
    }

    var body: some View {
        HStack(alignment: .top, spacing: Space.objectGap) {
            ForEach(columns.indices, id: \.self) { columnIndex in
                LazyVStack(spacing: Space.objectGap * 1.6) {
                    ForEach(columns[columnIndex]) { entry in
                        MemoryTile(
                            entry: entry,
                            width: tileWidth,
                            onOpen: { onOpen(entry) },
                            onToggleFavorite: { onToggleFavorite(entry) }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
