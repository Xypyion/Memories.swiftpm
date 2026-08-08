import SwiftUI

// MARK: - Vocabulary

enum StickerStyle: String, Codable, Hashable, CaseIterable {
    case neon, pink, paper, ink
}

enum NoteColor: String, Codable, Hashable, CaseIterable {
    case blush, paper, neon, lilac
}

enum DecorationKind: String, Codable, Hashable, CaseIterable {
    case star, sparkle, squiggle, ring, arrow
}

/// Presence ring around an avatar. `offline` rather than `none`, so the case
/// never collides with `Optional.none` at a call site.
enum RingStyle: String, Codable, Hashable {
    case neon, pink, offline
}

// MARK: - Payloads

struct PhotoPayload: Codable, Hashable {
    /// Filename inside `ImageStore`. `nil` means "draw the procedural texture".
    var imageName: String?
    var caption: String = ""
    var isFavorite: Bool = false
    /// width / height
    var aspect: Double = 0.8
}

struct NotePayload: Codable, Hashable {
    var text: String
    var color: NoteColor = .blush
}

struct StickerPayload: Codable, Hashable {
    var text: String
    var style: StickerStyle = .neon
}

// MARK: - Canvas item

/// Anything that can sit on a board.
enum CanvasItemKind: Codable, Hashable {
    case photo(PhotoPayload)
    case polaroid(PhotoPayload)
    case note(NotePayload)
    case sticker(StickerPayload)
    case decoration(DecorationKind)

    var isPhotographic: Bool {
        switch self {
        case .photo, .polaroid: true
        default: false
        }
    }

    var photo: PhotoPayload? {
        switch self {
        case .photo(let payload), .polaroid(let payload): payload
        default: nil
        }
    }

    var isPolaroid: Bool {
        if case .polaroid = self { return true }
        return false
    }

    var label: String {
        switch self {
        case .photo: "Photo"
        case .polaroid: "Polaroid"
        case .note: "Note"
        case .sticker: "Sticker"
        case .decoration: "Decoration"
        }
    }
}

struct CanvasItem: Identifiable, Codable, Hashable {

    var id: UUID = UUID()
    var kind: CanvasItemKind
    /// Centre point in the board's own 2200 × 1500 coordinate space.
    var position: CGPoint
    var rotation: Double = 0
    var scale: CGFloat = 1
    var zIndex: Double = 0
    var seed: Int = Int.random(in: 0 ..< 100_000)
    /// Base width before `scale` is applied.
    var width: CGFloat = 260

    /// When the memory happened. Optional so that documents written before this
    /// field existed still decode — see the `Decodable` extension below.
    var createdAt: Date?
    /// Free-text category, matched against `MemoryTopic` for display.
    var topic: String?

    /// Convenience for mutating the photo payload in place regardless of frame
    /// style, so photo editing code doesn't have to branch.
    var photoPayload: PhotoPayload? {
        get { kind.photo }
        set {
            guard let newValue else { return }
            switch kind {
            case .photo: kind = .photo(newValue)
            case .polaroid: kind = .polaroid(newValue)
            default: break
            }
        }
    }
}

/// Tolerant decoding.
///
/// Declared in an extension rather than in the body so the memberwise
/// initialiser survives. Every field is optional-with-fallback, which means a
/// `state.json` written by an older build of the app still loads: adding a
/// property can never again orphan somebody's boards. That guarantee is the
/// whole point — this data is the user's memories, and there is no server copy.
extension CanvasItem {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try container.decode(CanvasItemKind.self, forKey: .kind)
        position = try container.decodeIfPresent(CGPoint.self, forKey: .position) ?? .zero
        rotation = try container.decodeIfPresent(Double.self, forKey: .rotation) ?? 0
        scale = try container.decodeIfPresent(CGFloat.self, forKey: .scale) ?? 1
        zIndex = try container.decodeIfPresent(Double.self, forKey: .zIndex) ?? 0
        seed = try container.decodeIfPresent(Int.self, forKey: .seed) ?? 0
        width = try container.decodeIfPresent(CGFloat.self, forKey: .width) ?? 260
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        topic = try container.decodeIfPresent(String.self, forKey: .topic)
    }
}

/// A memory lifted out of its board, for surfaces that flatten every board into
/// one list. A concrete type rather than a tuple, because Swift key paths — which
/// `ForEach(id:)` needs — cannot address tuple elements.
struct MemoryEntry: Identifiable {

    var board: Board
    var item: CanvasItem

    var id: UUID { item.id }

    /// Items written before dates existed inherit their board's timestamp, so
    /// the day view is never empty for legacy data.
    var date: Date { item.createdAt ?? board.updatedAt }

    var topic: MemoryTopic { MemoryTopic.resolve(item.topic) }

    var caption: String { item.kind.photo?.caption ?? "" }
}

/// The topic catalogue.
///
/// Modelled as a value type with a fallback case rather than a closed enum, so a
/// topic string that isn't in the catalogue still groups correctly instead of
/// being dropped. New organisation schemes plug in the same way — see
/// `MemoryGrouping`.
struct MemoryTopic: Identifiable, Hashable {

    var name: String
    var icon: String
    var tint: TopicTint

    var id: String { name.lowercased() }

    enum TopicTint: String, Hashable {
        case neon, pink, lilac, blush, plain
    }

    static let catalogue: [MemoryTopic] = [
        MemoryTopic(name: "School", icon: "graduationcap", tint: .lilac),
        MemoryTopic(name: "Friends", icon: "person.2", tint: .pink),
        MemoryTopic(name: "Travel", icon: "airplane", tint: .neon),
        MemoryTopic(name: "Music", icon: "music.note", tint: .blush),
        MemoryTopic(name: "Food", icon: "fork.knife", tint: .neon),
        MemoryTopic(name: "Everyday", icon: "sun.horizon", tint: .plain)
    ]

    static let unfiled = MemoryTopic(name: "Unfiled", icon: "tray", tint: .plain)

    static func resolve(_ raw: String?) -> MemoryTopic {
        guard let raw, !raw.isEmpty else { return .unfiled }
        return catalogue.first { $0.name.caseInsensitiveCompare(raw) == .orderedSame }
            ?? MemoryTopic(name: raw, icon: "tag", tint: .plain)
    }
}

/// How the Memories tab is organised. Adding a third scheme means adding a case
/// here and a view — nothing else in the tab changes.
enum MemoryGrouping: String, CaseIterable, Identifiable {
    case day, topic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: "By day"
        case .topic: "By topic"
        }
    }

    var icon: String {
        switch self {
        case .day: "calendar"
        case .topic: "tag"
        }
    }
}

/// A length of twine between two items.
struct RopeConnection: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var a: UUID
    var b: UUID
    var sag: CGFloat = 0.20
}

// MARK: - Board

struct Board: Identifiable, Codable, Hashable {

    var id: UUID = UUID()
    var title: String
    var caption: String = ""
    var badge: String = ""
    var badgeStyle: StickerStyle = .neon
    var seed: Int = Int.random(in: 0 ..< 100_000)
    var updatedAt: Date = Date()
    var collaborators: [UUID] = []
    var items: [CanvasItem] = []
    var ropes: [RopeConnection] = []
    /// Drives the bento rhythm in the gallery.
    var tileWeight: TileWeight = .standard

    enum TileWeight: String, Codable, Hashable {
        case hero, tall, standard
    }

    var memoryCount: Int {
        items.filter { $0.kind.isPhotographic }.count
    }

    var topZIndex: Double {
        (items.map(\.zIndex).max() ?? 0) + 1
    }

    static let placeholder = Board(title: "—")
}

// MARK: - People

struct Friend: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var handle: String
    var seed: Int
    var isActive: Bool = false
    var ringStyle: RingStyle = .offline
    var avatarImageName: String?
}

struct Invite: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var friendID: UUID
    var boardName: String
}

struct ActivityEvent: Identifiable, Codable, Hashable {

    enum Kind: String, Codable, Hashable {
        case added, reacted, joined, commented
    }

    var id: UUID = UUID()
    var friendID: UUID
    var kind: Kind
    var detail: String
    var boardName: String
    var date: Date
    var photoSeeds: [Int] = []

    var verb: String {
        switch kind {
        case .added: "added \(detail) to"
        case .reacted: "reacted to \(detail) in"
        case .joined: "joined"
        case .commented: "commented on \(detail) in"
        }
    }
}

// MARK: - Profile

struct NowPlaying: Codable, Hashable {
    var title: String
    var artist: String
    var artSeed: Int
}

struct PinnedThing: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var seed: Int
}

struct UserProfile: Codable, Hashable {
    var handle: String
    var displayName: String
    var avatarSeed: Int
    var avatarImageName: String?
    var statusText: String
    var streak: Int
    var nowPlaying: NowPlaying
    var pinnedArtists: [PinnedThing]
    var hobbies: [String]
}

// MARK: - Time

enum RelativeTime {

    private static let formatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    static func string(for date: Date) -> String {
        formatter.localizedString(for: date, relativeTo: Date())
    }

    /// "Updated today" reads better than "Updated 4 hr ago" on a board tile.
    static func updatedString(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Updated today"
        }
        return "Updated \(string(for: date))"
    }
}
