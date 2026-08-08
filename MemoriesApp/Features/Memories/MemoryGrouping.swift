import SwiftUI

/// A titled run of memories — one day, or one topic.
///
/// Both organisation schemes produce the same shape, which is what lets the two
/// views share their entire presentation layer. A third scheme (by board, by
/// person, by place) only has to produce `[MemorySection]` and it inherits the
/// masonry, the empty states and the responsive behaviour for free.
struct MemorySection: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var icon: String
    var tint: Color
    var entries: [MemoryEntry]
}

enum MemoryGrouper {

    /// Newest day first, newest memory first within each day.
    static func byDay(_ entries: [MemoryEntry]) -> [MemorySection] {
        let calendar = Calendar.current
        let buckets = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }

        return buckets.keys.sorted(by: >).map { day in
            let items = (buckets[day] ?? []).sorted { $0.date > $1.date }
            return MemorySection(
                id: ISO8601DateFormatter().string(from: day),
                title: dayTitle(for: day, calendar: calendar),
                subtitle: "\(items.count) \(items.count == 1 ? "memory" : "memories")",
                icon: "calendar",
                tint: Palette.accent,
                entries: items
            )
        }
    }

    /// Catalogue order first so the list is stable, then anything the user
    /// invented, then unfiled last — nobody wants their leftovers at the top.
    static func byTopic(_ entries: [MemoryEntry]) -> [MemorySection] {
        let buckets = Dictionary(grouping: entries) { $0.topic }

        let ordered = buckets.keys.sorted { lhs, rhs in
            let lhsIndex = MemoryTopic.catalogue.firstIndex(of: lhs) ?? Int.max - 1
            let rhsIndex = MemoryTopic.catalogue.firstIndex(of: rhs) ?? Int.max - 1
            if lhs == .unfiled { return false }
            if rhs == .unfiled { return true }
            if lhsIndex != rhsIndex { return lhsIndex < rhsIndex }
            return lhs.name < rhs.name
        }

        return ordered.map { topic in
            let items = (buckets[topic] ?? []).sorted { $0.date > $1.date }
            return MemorySection(
                id: topic.id,
                title: topic.name,
                subtitle: "\(items.count) \(items.count == 1 ? "memory" : "memories")",
                icon: topic.icon,
                tint: topic.tint.color,
                entries: items
            )
        }
    }

    private static func dayTitle(for day: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }

        let isThisYear = calendar.component(.year, from: day) == calendar.component(.year, from: Date())
        return isThisYear
            ? day.formatted(.dateTime.weekday(.wide).month(.wide).day())
            : day.formatted(.dateTime.month(.wide).day().year())
    }
}

extension MemoryTopic.TopicTint {
    var color: Color {
        switch self {
        case .neon: Palette.accent
        case .pink: Palette.pinkAccent
        case .lilac: Color(hex: 0x8B87C7)
        case .blush: Color(hex: 0xC97389)
        case .plain: Palette.onSurfaceVariant
        }
    }
}
