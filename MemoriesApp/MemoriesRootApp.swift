import SwiftUI

@main
struct MemoriesRootApp: App {

    @StateObject private var store = AppStore()
    @StateObject private var account = AccountStore()
    @StateObject private var preferences = Preferences()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(account)
                .environmentObject(preferences)
                // `nil` under "System" hands control back to the iPad's own
                // setting rather than pinning the app to one appearance.
                .preferredColorScheme(preferences.colorScheme)
                .tint(Palette.accent)
        }
    }
}
