import SwiftUI

// MARK: - Hero Transition Namespace Environment Key

/// Environment key for sharing the hero transition namespace across views.
struct HeroTransitionNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    /// The shared namespace for hero transition animations.
    var heroTransitionNamespace: Namespace.ID? {
        get { self[HeroTransitionNamespaceKey.self] }
        set { self[HeroTransitionNamespaceKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Provides a hero transition namespace to all descendant views.
    func heroTransitionNamespace(_ namespace: Namespace.ID) -> some View {
        environment(\.heroTransitionNamespace, namespace)
    }
}
