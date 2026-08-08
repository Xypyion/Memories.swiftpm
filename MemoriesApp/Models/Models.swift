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

/// A memory lifted out of its board, for surfaces that flatten every board into
/// one list. A concrete type rather than a tuple, because Swift key paths — which
/// `ForEach(id:)` needs — cannot address tuple elements.
struct MemoryEntry: Identifiable {
    var board: Board
    var item: CanvasItem
    var id: UUID { item.id }
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
