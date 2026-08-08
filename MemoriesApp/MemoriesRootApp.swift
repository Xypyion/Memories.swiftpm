import SwiftUI

@main
struct MemoriesRootApp: App {

    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(Palette.neon)
        }
    }
}
