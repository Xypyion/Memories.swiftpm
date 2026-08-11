import SwiftUI

/// Every memory in the app, flattened out of its boards.
///
/// The gallery answers "what collections do I have"; this answers "where is that
/// one photo". Two organisation schemes sit on top of the same filtered data:
///
/// * **By day** — chronological, newest first, for walking back through time.
/// * **By topic** — grouped by category, for "show me everything from school".
///
/// Switching between them changes one `@State` enum and re-runs a pure grouping
/// function. Nothing reloads, nothing refetches, and the search text and filter
/// chips survive the switch — which is the whole point of keeping the filter
/// pipeline above the grouping rather than inside each view.
struct MemoriesView: View {

    @EnvironmentObject private var store: AppStore

    @State private var grouping: MemoryGrouping = .day
    @State private var filter: MemoryFilter = .all
    @State private var query = ""

    var body: some View {
        GeometryReader { geo in
            let contentWidth = min(geo.size.width, 1440) - horizontalPadding(for: geo.size.width) * 2

            ScrollView {
                LazyVStack(alignment: .leading, spacing: Space.unit * 4, pinnedViews: []) {
                    ScrollOffsetReporter()

                    header(isWide: geo.size.width > 820)
                    controls

                    if sections.isEmpty {
                        emptyState
                    } else {
                        ForEach(sections) { section in
                            VStack(alignment: .leading, spacing: Space.unit * 2) {
                                MemorySectionHeader(section: section)

                                MemoryMasonry(
                                    entries: section.entries,
                                    availableWidth: contentWidth,
                                    onOpen: open,
                                    onToggleFavorite: toggleFavorite
                                )
                            }
                            .padding(.bottom, Space.unit)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding(for: geo.size.width))
                .padding(.top, Space.topBarClearance)
                .padding(.bottom, Space.dockClearance)
                .frame(maxWidth: 1440)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .tracksScrollOffset()
            .background(Palette.void)
        }
    }

    // MARK: Chrome

    private func header(isWide: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All memories")
                .textStyle(TypeScale.labelCaps)
                .foregroundStyle(Palette.accent)

            Text("Everything, everywhere")
                .textStyle(isWide ? TypeScale.displayLG : TypeScale.displayMD)
                .foregroundStyle(Palette.onSurface)

            Text("\(store.allMemories.count) memories across \(store.boards.count) boards.")
                .textStyle(TypeScale.bodyLG)
                .foregroundStyle(Palette.onSurfaceVariant)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: Space.unit * 2) {
            MemoryViewToggle(grouping: $grouping)
            searchField
            filters
        }
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
        .background(Palette.charcoal, in: Capsule())
        .overlay {
            Capsule().strokeBorder(query.isEmpty ? Palette.hairline : Palette.accent.opacity(0.6), lineWidth: 1)
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

    private var emptyState: some View {
        VStack(spacing: 14) {
            DecorationView(kind: .sparkle, size: 52, color: Palette.onSurfaceVariant.opacity(0.4))

            Text("Nothing here yet")
                .textStyle(TypeScale.headline)
                .foregroundStyle(Palette.onSurface)

            Text(emptyMessage)
                .textStyle(TypeScale.bodyMD)
                .foregroundStyle(Palette.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    private var emptyMessage: String {
        if !query.isEmpty { return "No memory matches “\(query)”." }
        if filter != .all { return "No memories match this filter." }
        return "Open a board and drop a photo onto the canvas."
    }

    // MARK: Data

    /// Filter first, group second. Keeping it in this order is what lets the two
    /// schemes share a pipeline instead of each re-implementing search.
    private var sections: [MemorySection] {
        let filtered = store.allMemories
            .filter(matchesFilter)
            .filter(matchesQuery)

        switch grouping {
        case .day: return MemoryGrouper.byDay(filtered)
        case .topic: return MemoryGrouper.byTopic(filtered)
        }
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
        return entry.caption.localizedCaseInsensitiveContains(query)
            || entry.board.title.localizedCaseInsensitiveContains(query)
            || entry.topic.name.localizedCaseInsensitiveContains(query)
    }

    // MARK: Actions

    private func open(_ entry: MemoryEntry) {
        store.openBoardID = entry.board.id
        store.tab = .board
    }

    private func toggleFavorite(_ entry: MemoryEntry) {
        store.toggleFavorite(boardID: entry.board.id, itemID: entry.item.id)
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width > 700 ? Space.canvasMargin : Space.unit * 2.5
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
