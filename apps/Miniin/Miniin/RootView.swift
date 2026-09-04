import MiniinKit
import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text(verbatim: "Miniin")
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.contentPrimary)

            Text("app.tagline")
                .font(AppFont.body)
                .foregroundStyle(AppColor.contentSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
        .tint(AppColor.accent)
    }
}

#Preview("Light") {
    RootView().preferredColorScheme(.light)
}

#Preview("Dark") {
    RootView().preferredColorScheme(.dark)
}
