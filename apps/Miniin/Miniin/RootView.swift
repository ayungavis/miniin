import MiniinKit
import SwiftUI

struct RootView: View {
    let container: AppContainer

    var body: some View {
        CompressionView(model: container.compression)
            .task { await container.queue.observe() }
    }
}

#Preview("Light") {
    RootView(container: AppContainer()).preferredColorScheme(.light)
}

#Preview("Dark") {
    RootView(container: AppContainer()).preferredColorScheme(.dark)
}
