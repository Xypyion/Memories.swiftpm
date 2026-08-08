import SwiftUI

/// Everything the user can change about how the app behaves, as opposed to what
/// is on their boards.
///
/// Kept in its own store so that flipping a notification toggle does not
/// invalidate every view subscribed to the board data — the single biggest
/// avoidable source of re-render churn in an app of this shape.
final class Preferences: ObservableObject {

    @Published var themeMode: ThemeMode { didSet { save() } }
    @Published var reduceMotion: Bool { didSet { save() } }
    @Published var showsPresenceDemo: Bool { didSet { save() } }

    @Published var notifyOnInvite: Bool { didSet { save() } }
    @Published var notifyOnActivity: Bool { didSet { save() } }
    @Published var notifyOnReaction: Bool { didSet { save() } }

    @Published var profileVisibility: ProfileVisibility { didSet { save() } }
    @Published var showsActivityStatus: Bool { didSet { save() } }
    @Published var allowsInvitesFromAnyone: Bool { didSet { save() } }

    private static let key = "memories.preferences.v1"
    private var isLoading = true

    init() {
        let stored = Preferences.load()
        themeMode = stored?.themeMode ?? .system
        reduceMotion = stored?.reduceMotion ?? false
        showsPresenceDemo = stored?.showsPresenceDemo ?? true
        notifyOnInvite = stored?.notifyOnInvite ?? true
        notifyOnActivity = stored?.notifyOnActivity ?? true
        notifyOnReaction = stored?.notifyOnReaction ?? false
        profileVisibility = stored?.profileVisibility ?? .friends
        showsActivityStatus = stored?.showsActivityStatus ?? true
        allowsInvitesFromAnyone = stored?.allowsInvitesFromAnyone ?? false
        isLoading = false
    }

    /// `nil` hands control back to the system setting.
    var colorScheme: ColorScheme? {
        switch themeMode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    func resetToDefaults() {
        themeMode = .system
        reduceMotion = false
        showsPresenceDemo = true
        notifyOnInvite = true
        notifyOnActivity = true
        notifyOnReaction = false
        profileVisibility = .friends
        showsActivityStatus = true
        allowsInvitesFromAnyone = false
    }

    // MARK: Persistence

    private struct Snapshot: Codable {
        var themeMode: ThemeMode
        var reduceMotion: Bool
        var showsPresenceDemo: Bool
        var notifyOnInvite: Bool
        var notifyOnActivity: Bool
        var notifyOnReaction: Bool
        var profileVisibility: ProfileVisibility
        var showsActivityStatus: Bool
        var allowsInvitesFromAnyone: Bool
    }

    private static func load() -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    private func save() {
        guard !isLoading else { return }
        let snapshot = Snapshot(
            themeMode: themeMode,
            reduceMotion: reduceMotion,
            showsPresenceDemo: showsPresenceDemo,
            notifyOnInvite: notifyOnInvite,
            notifyOnActivity: notifyOnActivity,
            notifyOnReaction: notifyOnReaction,
            profileVisibility: profileVisibility,
            showsActivityStatus: showsActivityStatus,
            allowsInvitesFromAnyone: allowsInvitesFromAnyone
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Preferences.key)
    }
}

enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon.stars"
        }
    }
}

enum ProfileVisibility: String, Codable, CaseIterable, Identifiable {
    case everyone, friends, onlyMe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .everyone: "Everyone"
        case .friends: "Friends"
        case .onlyMe: "Only me"
        }
    }
}

/// Resolves whether motion should be reduced, honouring both the system
/// accessibility setting and the app's own override.
///
/// Read this instead of `@Environment(\.accessibilityReduceMotion)` directly, so
/// that one switch in Settings governs every animation in the app.
struct MotionPolicy {

    let systemPrefersReduced: Bool
    let appPrefersReduced: Bool

    var isReduced: Bool { systemPrefersReduced || appPrefersReduced }

    /// An animation that collapses to `nil` (no animation) when motion is
    /// reduced.
    func animation(_ animation: Animation?) -> Animation? {
        isReduced ? nil : animation
    }
}

private struct MotionPolicyKey: EnvironmentKey {
    static let defaultValue = MotionPolicy(systemPrefersReduced: false, appPrefersReduced: false)
}

extension EnvironmentValues {
    var motionPolicy: MotionPolicy {
        get { self[MotionPolicyKey.self] }
        set { self[MotionPolicyKey.self] = newValue }
    }
}
