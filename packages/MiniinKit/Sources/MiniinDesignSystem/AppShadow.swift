import SwiftUI

public enum AppShadowLevel: Sendable {
    case card
    case raised
}

public extension View {
    func appShadow(_ level: AppShadowLevel = .card) -> some View {
        modifier(AppShadowModifier(level: level))
    }
}

private struct AppShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let level: AppShadowLevel

    func body(content: Content) -> some View {
        content.shadow(color: color, radius: radius, x: 0, y: offsetY)
    }

    private var color: Color {
        colorScheme == .dark ? .black.opacity(0.55) : .black.opacity(0.10)
    }

    private var radius: CGFloat {
        switch level {
        case .card: colorScheme == .dark ? 10 : 6
        case .raised: colorScheme == .dark ? 22 : 14
        }
    }

    private var offsetY: CGFloat {
        switch level {
        case .card: 2
        case .raised: 6
        }
    }
}
