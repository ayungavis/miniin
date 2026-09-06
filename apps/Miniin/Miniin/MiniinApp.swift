import SwiftUI

@main
struct MiniinApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 620)
        #endif
    }
}
