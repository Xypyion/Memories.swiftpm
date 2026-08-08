import SwiftUI

/// The signed-in person.
///
/// Distinct from `UserProfile`, deliberately. `UserProfile` is the *expressive*
/// layer — the status bubble, the record, the hobby stickers, the things a user
/// arranges. `UserAccount` is *identity*: who you are, what you're called, and
/// what the app should call you when it addresses you. They persist separately
/// because they answer to different owners — identity would come from an auth
/// backend, the Personality Board never would.
struct UserAccount: Codable, Hashable, Identifiable {

    var id: UUID = UUID()
    var username: String
    var displayName: String
    var email: String
    var bio: String
    var avatarSeed: Int
    var avatarImageName: String?
    var joinedAt: Date
    /// Set when the account came from "continue as guest" rather than sign-in.
    var isGuest: Bool = false

    var handle: String { "@\(username)" }

    var initials: String {
        let parts = displayName.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    static func guest() -> UserAccount {
        UserAccount(
            username: "guest",
            displayName: "Guest",
            email: "",
            bio: "Just looking around.",
            avatarSeed: .seed(from: "guest"),
            joinedAt: Date(),
            isGuest: true
        )
    }
}

/// Session and first-run state.
///
/// There is no auth backend. This models the *shape* one would take — a session
/// that can be absent, restored, mutated and cleared — so that swapping the
/// local store for a real identity provider is a change inside `signIn` and
/// `restore`, not a change to every view that asks who the user is.
final class AccountStore: ObservableObject {

    @Published private(set) var account: UserAccount?
    @Published private(set) var hasCompletedOnboarding: Bool
    @Published var authError: String?

    var isSignedIn: Bool { account != nil }

    private static let accountKey = "memories.account.v1"
    private static let onboardingKey = "memories.onboarding.completed.v1"

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: AccountStore.onboardingKey)

        if let data = UserDefaults.standard.data(forKey: AccountStore.accountKey),
           let restored = try? JSONDecoder().decode(UserAccount.self, from: data) {
            account = restored
        }
    }

    // MARK: Auth

    /// Local sign-in. Validates the shape of the input the way a real endpoint
    /// would, then mints a session. Replace the body — not the signature — when
    /// a backend exists.
    func signIn(username rawUsername: String, displayName rawDisplayName: String) {
        let username = AccountValidator.normalisedUsername(rawUsername)
        let displayName = rawDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)

        if let problem = AccountValidator.usernameProblem(username) {
            authError = problem
            return
        }

        authError = nil
        let resolvedName = displayName.isEmpty ? username : displayName

        account = UserAccount(
            username: username,
            displayName: resolvedName,
            email: "",
            bio: "",
            avatarSeed: .seed(from: username),
            joinedAt: Date(),
            isGuest: false
        )
        persist()
    }

    func continueAsGuest() {
        authError = nil
        account = .guest()
        persist()
    }

    func signOut() {
        account = nil
        UserDefaults.standard.removeObject(forKey: AccountStore.accountKey)
    }

    /// Promotes a guest session into a named account, keeping everything they
    /// already made. Guest work is not throwaway work.
    func claimGuestAccount(username: String, displayName: String) {
        guard var existing = account else {
            signIn(username: username, displayName: displayName)
            return
        }
        let normalised = AccountValidator.normalisedUsername(username)
        if let problem = AccountValidator.usernameProblem(normalised) {
            authError = problem
            return
        }
        authError = nil
        existing.username = normalised
        existing.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        existing.isGuest = false
        account = existing
        persist()
    }

    // MARK: Mutation

    func update(_ transform: (inout UserAccount) -> Void) {
        guard var existing = account else { return }
        transform(&existing)
        account = existing
        persist()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: AccountStore.onboardingKey)
    }

    /// Exposed so Settings can offer "replay the tutorial".
    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: AccountStore.onboardingKey)
    }

    private func persist() {
        guard let account, let data = try? JSONEncoder().encode(account) else { return }
        UserDefaults.standard.set(data, forKey: AccountStore.accountKey)
    }
}

/// Input rules, kept out of the views so the login screen and the profile editor
/// cannot disagree about what a valid username is.
enum AccountValidator {

    static func normalisedUsername(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "@", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    /// Returns a human-readable problem, or `nil` if the value is acceptable.
    static func usernameProblem(_ username: String) -> String? {
        if username.isEmpty {
            return "Pick a username."
        }
        if username.count < 3 {
            return "Usernames need at least 3 characters."
        }
        if username.count > 20 {
            return "Usernames can be at most 20 characters."
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._"))
        if username.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return "Letters, numbers, dots and underscores only."
        }
        return nil
    }

    static func displayNameProblem(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Add a display name." }
        if trimmed.count > 40 { return "Display names can be at most 40 characters." }
        return nil
    }

    static func bioProblem(_ bio: String) -> String? {
        bio.count > 160 ? "Bios can be at most 160 characters." : nil
    }
}
