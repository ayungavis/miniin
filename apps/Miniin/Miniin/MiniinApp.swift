import SwiftUI

@main
struct MiniinApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 620)
        #endif
    }
}
