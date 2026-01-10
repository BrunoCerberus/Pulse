import SwiftUI

// MARK: - Hero Transition Source Modifier

/// Marks a view as the source for a hero transition animation.
struct HeroTransitionSourceModifier: ViewModifier {
    let articleId: String
    let hasImage: Bool
    @Environment(\.heroTransitionNamespace) private var namespace

    func body(content: Content) -> some View {
        if let namespace, hasImage {
            content
                .matchedTransitionSource(id: articleId, in: namespace)
        } else {
            content
        }
    }
}

// MARK: - Hero Transition Destination Modifier

/// Marks a view as the destination for a hero transition animation.
struct HeroTransitionDestinationModifier: ViewModifier {
    let articleId: String
    let hasImage: Bool
    @Environment(\.heroTransitionNamespace) private var namespace

    func body(content: Content) -> some View {
        if let namespace, hasImage {
            content
                .navigationTransition(.zoom(sourceID: articleId, in: namespace))
        } else {
            content
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Marks this view as the source for a hero transition.
    /// - Parameters:
    ///   - articleId: Unique identifier for the article
    ///   - hasImage: Whether the article has an image to animate
    func heroTransitionSource(articleId: String, hasImage: Bool) -> some View {
        modifier(HeroTransitionSourceModifier(articleId: articleId, hasImage: hasImage))
    }

    /// Marks this view as the destination for a hero transition.
    /// - Parameters:
    ///   - articleId: Unique identifier for the article
    ///   - hasImage: Whether the article has an image to animate
    func heroTransitionDestination(articleId: String, hasImage: Bool) -> some View {
        modifier(HeroTransitionDestinationModifier(articleId: articleId, hasImage: hasImage))
    }
}
