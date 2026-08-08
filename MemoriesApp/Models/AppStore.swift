import Combine
import SwiftUI

/// Single source of truth. Everything the user creates lives here and is
/// mirrored to a JSON document in Application Support.
///
/// Writes are debounced by one second: dragging a photo across the board
/// mutates state at display rate, and persisting on every frame would be
/// pointless disk churn.
final class AppStore: ObservableObject {

    @Published var boards: [Board]
    @Published var friends: [Friend]
    @Published var invites: [Invite]
    @Published var activity: [ActivityEvent]
    @Published var profile: UserProfile

    // Navigation state. Deliberately not persisted — the app should always open
    // on the gallery.
    @Published var tab: AppTab = .board
    @Published var openBoardID: UUID?

    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    init() {
        if let snapshot = AppStore.loadSnapshot() {
            boards = snapshot.boards
            friends = snapshot.friends
            invites = snapshot.invites
            activity = snapshot.activity
            profile = snapshot.profile
        } else {
            let seeded = SampleData.make()
            boards = seeded.boards
            friends = seeded.friends
            invites = seeded.invites
            activity = seeded.activity
            profile = seeded.profile
        }

        objectWillChange
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.persist() }
            .store(in: &cancellables)
    }

    // MARK: Lookups

    func board(id: UUID) -> Board? {
        boards.first { $0.id == id }
    }

    func friend(id: UUID) -> Friend? {
        friends.first { $0.id == id }
    }

    func collaborators(for board: Board) -> [Friend] {
        board.collaborators.compactMap { friend(id: $0) }
    }

    /// A two-way binding to a board by identity, so the editor can mutate items
    /// in place without copying the whole board in and out.
    func binding(forBoard id: UUID) -> Binding<Board> {
        Binding(
            get: { [weak self] in
                self?.boards.first { $0.id == id } ?? .placeholder
            },
            set: { [weak self] newValue in
                guard let self else { return }
                guard let index = self.boards.firstIndex(where: { $0.id == id }) else { return }
                self.boards[index] = newValue
            }
        )
    }

    /// Every photographic item in the app, newest board first. Backs the
    /// Memories tab.
    var allMemories: [MemoryEntry] {
        boards
            .sorted { $0.updatedAt > $1.updatedAt }
            .flatMap { board in
                board.items
                    .filter { $0.kind.isPhotographic }
                    .map { MemoryEntry(board: board, item: $0) }
            }
    }

    // MARK: Mutation

    func createBoard() -> UUID {
        let board = Board(
            title: "Untitled Board",
            caption: "Start dropping things in.",
            badge: "New",
            badgeStyle: .neon,
            collaborators: friends.prefix(2).map(\.id),
            items: [],
            tileWeight: .standard
        )
        boards.insert(board, at: 0)
        return board.id
    }

    func deleteBoard(id: UUID) {
        if let board = board(id: id) {
            for item in board.items {
                if let name = item.kind.photo?.imageName {
                    ImageStore.delete(named: name)
                }
            }
        }
        boards.removeAll { $0.id == id }
        if openBoardID == id { openBoardID = nil }
    }

    func touch(boardID: UUID) {
        guard let index = boards.firstIndex(where: { $0.id == boardID }) else { return }
        boards[index].updatedAt = Date()
    }

    func acceptInvite(_ invite: Invite) {
        invites.removeAll { $0.id == invite.id }
        guard let friend = friend(id: invite.friendID) else { return }
        activity.insert(
            ActivityEvent(
                friendID: friend.id,
                kind: .joined,
                detail: "",
                boardName: invite.boardName,
                date: Date()
            ),
            at: 0
        )
    }

    func declineInvite(_ invite: Invite) {
        invites.removeAll { $0.id == invite.id }
    }

    func toggleFavorite(boardID: UUID, itemID: UUID) {
        guard
            let boardIndex = boards.firstIndex(where: { $0.id == boardID }),
            let itemIndex = boards[boardIndex].items.firstIndex(where: { $0.id == itemID }),
            var payload = boards[boardIndex].items[itemIndex].kind.photo
        else { return }

        payload.isFavorite.toggle()
        boards[boardIndex].items[itemIndex].photoPayload = payload
    }

    // MARK: Persistence

    private struct Snapshot: Codable {
        var boards: [Board]
        var friends: [Friend]
        var invites: [Invite]
        var activity: [ActivityEvent]
        var profile: UserProfile
    }

    private static var stateURL: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Memories", isDirectory: true)

        if !FileManager.default.fileExists(atPath: base.path) {
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base.appendingPathComponent("state.json")
    }

    private static func loadSnapshot() -> Snapshot? {
        guard let data = try? Data(contentsOf: stateURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Snapshot.self, from: data)
    }

    func persist() {
        let snapshot = Snapshot(
            boards: boards,
            friends: friends,
            invites: invites,
            activity: activity,
            profile: profile
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: AppStore.stateURL, options: .atomic)
    }

    /// Wipes saved state and reloads the seeded sample board set.
    func resetToSample() {
        let seeded = SampleData.make()
        boards = seeded.boards
        friends = seeded.friends
        invites = seeded.invites
        activity = seeded.activity
        profile = seeded.profile
        openBoardID = nil
        persist()
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case board, memories, friends, profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .board: "Board"
        case .memories: "Memories"
        case .friends: "Friends"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .board: "square.grid.2x2"
        case .memories: "photo.on.rectangle.angled"
        case .friends: "person.2"
        case .profile: "person.crop.circle"
        }
    }

    var filledIcon: String {
        switch self {
        case .board: "square.grid.2x2.fill"
        case .memories: "photo.on.rectangle.angled"
        case .friends: "person.2.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}
