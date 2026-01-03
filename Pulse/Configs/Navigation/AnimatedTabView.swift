import SwiftUI

/// A TabView wrapper that adds symbol effect animations to tab bar icons.
///
/// This view extracts the UIImageViews from the system UITabBar and applies
/// symbol effects directly to them when the selection changes, enabling
/// animations with the native Liquid Glass tab bar.
struct AnimatedTabView<Selection: AnimatedTabSelectionProtocol, Content: TabContent<Selection>>: View {
    @Binding var selection: Selection
    @TabContentBuilder<Selection> var content: Content
    var effects: (Selection) -> any DiscreteSymbolEffect & SymbolEffect

    @State private var imageViews: [Selection: UIImageView] = [:]

    init(
        selection: Binding<Selection>,
        @TabContentBuilder<Selection> content: () -> Content,
        effects: @escaping (Selection) -> any DiscreteSymbolEffect & SymbolEffect
    ) {
        _selection = selection
        self.content = content()
        self.effects = effects
    }

    var body: some View {
        TabView(selection: $selection) {
            content
        }
        .tabViewStyle(.tabBarOnly)
        .background(ExtractImageViewsFromTabView<Selection>(imageViews: $imageViews))
        .compositingGroup()
        .onChange(of: selection) { _, newValue in
            let symbolEffect = effects(newValue)
            guard let imageView = imageViews[newValue] else { return }

            imageView.addSymbolEffect(symbolEffect, options: .nonRepeating)
        }
    }
}

// MARK: - UIViewRepresentable for Extracting Tab Bar Image Views

/// Extracts UIImageViews from the UITabBar to enable symbol effect animations.
private struct ExtractImageViewsFromTabView<Value: AnimatedTabSelectionProtocol>: UIViewRepresentable {
    @Binding var imageViews: [Value: UIImageView]

    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context _: Context) {
        guard let tabBar = uiView.tabBar else { return }
        extractImageViews(tabBar)
    }

    private func extractImageViews(_ tabBar: UITabBar) {
        let imageViews = tabBar.subviews(ofType: UIImageView.self)
            // Filter to only symbol images
            .filter { $0.image?.isSymbolImage ?? false }
            // Filter out active tinted images for iOS 26+
            .filter { isIOS26 ? ($0.tintColor == tabBar.tintColor) : true }

        var dict: [Value: UIImageView] = [:]

        for tab in Value.allCases {
            // Find the image view matching this tab's symbol
            if let imageView = imageViews.first(where: {
                $0.image?.description.contains(tab.symbolImage) ?? false
            }) {
                dict[tab] = imageView
            }
        }

        imageViews.isEmpty ? () : (self.imageViews = dict)
    }

    private var isIOS26: Bool {
        if #available(iOS 26, *) {
            return true
        }
        return false
    }
}

// MARK: - UIView Extensions

private extension UIView {
    /// Finds the UITabBar in the view hierarchy by traversing up to find the window,
    /// then searching down through all subviews.
    var tabBar: UITabBar? {
        // First, find the window by traversing up
        var current: UIView? = self
        while let view = current {
            if let window = view as? UIWindow {
                return window.findSubview(ofType: UITabBar.self)
            }
            current = view.superview
        }
        return nil
    }

    /// Finds the first subview of a specific type using breadth-first search.
    func findSubview<T: UIView>(ofType _: T.Type) -> T? {
        var queue: [UIView] = [self]

        while !queue.isEmpty {
            let current = queue.removeFirst()
            if let match = current as? T {
                return match
            }
            queue.append(contentsOf: current.subviews)
        }

        return nil
    }

    /// Recursively finds all subviews of a specific type.
    func subviews<T: UIView>(ofType type: T.Type) -> [T] {
        var result: [T] = []

        for subview in subviews {
            if let match = subview as? T {
                result.append(match)
            }
            result.append(contentsOf: subview.subviews(ofType: type))
        }

        return result
    }
}
