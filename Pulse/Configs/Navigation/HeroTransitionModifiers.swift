import SwiftUI

// MARK: - Hero Transition Source Modifier

/// Marks a view as the source for a hero transition animation.
struct HeroTransitionSourceModifier: ViewModifier {
    let articleId: String
    let hasImage: Bool
    let cornerRadius: CGFloat
    @Environment(\.heroTransitionNamespace) private var namespace

    func body(content: Content) -> some View {
        if let namespace, hasImage {
            content
                .matchedTransitionSource(id: articleId, in: namespace) { configuration in
                    configuration
                        .background(.clear)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
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
    ///   - cornerRadius: Corner radius for the transition clip shape
    func heroTransitionSource(
        articleId: String,
        hasImage: Bool,
        cornerRadius: CGFloat = CornerRadius.sm
    ) -> some View {
        modifier(HeroTransitionSourceModifier(
            articleId: articleId,
            hasImage: hasImage,
            cornerRadius: cornerRadius
        ))
    }

    /// Marks this view as the destination for a hero transition.
    /// - Parameters:
    ///   - articleId: Unique identifier for the article
    ///   - hasImage: Whether the article has an image to animate
    func heroTransitionDestination(articleId: String, hasImage: Bool) -> some View {
        modifier(HeroTransitionDestinationModifier(articleId: articleId, hasImage: hasImage))
    }
}
