import SwiftUI

@main
struct MemoriesRootApp: App {

    @StateObject private var store = AppStore()
    @StateObject private var account = AccountStore()
    @StateObject private var preferences = Preferences()

    /// The system's own accessibility setting. Combined with the app's override
    /// into a single `MotionPolicy` so no view has to check two sources.
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(account)
                .environmentObject(preferences)
                .environment(
                    \.motionPolicy,
                    MotionPolicy(
                        systemPrefersReduced: systemReduceMotion,
                        appPrefersReduced: preferences.reduceMotion
                    )
                )
                // `nil` under "System" hands control back to the iPad's own
                // setting rather than pinning the app to one appearance.
                .preferredColorScheme(preferences.colorScheme)
                .tint(Palette.accent)
        }
    }
}
