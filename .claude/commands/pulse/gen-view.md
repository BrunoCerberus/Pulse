# Generate View

Creates a SwiftUI View with router injection and ViewModel binding.

## Usage

```
/pulse:gen-view <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name (e.g., `Profile`, `Notifications`)

## Output Location

```
Pulse/<FeatureName>/View/<FeatureName>View.swift
```

## Template

```swift
import SwiftUI

struct <FeatureName>View<R: <FeatureName>NavigationRouter>: View {
    // MARK: - Properties

    private var router: R
    @ObservedObject var viewModel: <FeatureName>ViewModel

    // MARK: - Constants

    private enum Constants {
        static let title = "<Feature Name>"
        static let spacing: CGFloat = 12
        static let padding: CGFloat = 16
    }

    // MARK: - Initialization

    init(router: R, viewModel: <FeatureName>ViewModel) {
        self.router = router
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ColorSystem.backgroundPrimary
                .ignoresSafeArea()

            content
        }
        .navigationTitle(Constants.title)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.shared.tap()
                    router.route(navigationEvent: .settings)
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(ColorSystem.textPrimary)
                }
            }
        }
        .refreshable {
            HapticManager.shared.refresh()
            viewModel.handle(event: .onRefresh)
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
        .onChange(of: viewModel.viewState.selected<Entity>) { _, newValue in
            if let item = newValue {
                router.route(navigationEvent: .<entity>Detail(item))
                viewModel.handle(event: .on<Entity>Navigated)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.viewState.isLoading {
            loadingView
        } else if viewModel.viewState.showEmptyState {
            emptyState
        } else if let error = viewModel.viewState.errorMessage {
            errorView(error)
        } else {
            listContent
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: Constants.spacing) {
                ForEach(viewModel.viewState.items) { item in
                    <Entity>Card(item: item)
                        .onTapGesture {
                            HapticManager.shared.tap()
                            viewModel.handle(event: .on<Entity>Tapped(id: item.id))
                        }
                        .onAppear {
                            // Trigger pagination when near end
                            if item == viewModel.viewState.items.last {
                                viewModel.handle(event: .onLoadMore)
                            }
                        }
                }

                if viewModel.viewState.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding(Constants.padding)
        }
    }

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No items yet")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Pull to refresh or check back later")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Something went wrong")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.handle(event: .onRefresh)
            } label: {
                Text("Try Again")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        <FeatureName>View(
            router: <FeatureName>NavigationRouter(),
            viewModel: <FeatureName>ViewModel(serviceLocator: ServiceLocator.preview)
        )
    }
}
#endif
```

## Key Patterns

1. **Generic over Router type** - `<R: NavigationRouter>` for testability
2. **Use `@ObservedObject`** - ViewModel observation
3. **Send events via `viewModel.handle(event:)`** - Not direct method calls
4. **Navigate via `router.route(navigationEvent:)`** - Not coordinator directly
5. **Use `onChange` for navigation** - React to selectedEntity changes
6. **Include haptic feedback** - `HapticManager.shared.tap()`

## View Hierarchy

```
ZStack (background + content)
├── Background color (ignoresSafeArea)
└── content (@ViewBuilder)
    ├── loadingView (isLoading)
    ├── emptyState (showEmptyState)
    ├── errorView (errorMessage != nil)
    └── listContent (default)
```

## Navigation Pattern

```swift
// In View body
.onChange(of: viewModel.viewState.selectedEntity) { _, newValue in
    if let entity = newValue {
        // 1. Route to detail
        router.route(navigationEvent: .entityDetail(entity))
        // 2. Clear selection to allow re-navigation
        viewModel.handle(event: .onEntityNavigated)
    }
}
```

## Pagination Pattern

```swift
ForEach(viewModel.viewState.items) { item in
    ItemCard(item: item)
        .onAppear {
            if item == viewModel.viewState.items.last {
                viewModel.handle(event: .onLoadMore)
            }
        }
}
```

## Sheet/Share Pattern

```swift
.sheet(item: Binding(
    get: { viewModel.viewState.entityToShare },
    set: { _ in viewModel.handle(event: .onShareDismissed) }
)) { entity in
    ShareSheet(items: [entity.shareURL])
}
```

## Common Modifiers

```swift
.navigationTitle("Title")
.toolbarBackground(.hidden, for: .navigationBar)
.refreshable { viewModel.handle(event: .onRefresh) }
.onAppear { viewModel.handle(event: .onAppear) }
.searchable(text: ..., prompt: "Search...")
```

## Instructions

1. **Require ViewModel and Router exist** - Must exist first
2. Ask about **navigation destinations** (detail, settings, etc.)
3. Ask about **toolbar items** needed
4. Ask about **list item actions** (swipe, context menu)
5. Create the file following the template
6. Create matching card component if needed
