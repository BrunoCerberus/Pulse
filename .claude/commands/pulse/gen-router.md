# Generate NavigationRouter

Creates a NavigationRouter for feature-specific navigation.

## Usage

```
/pulse:gen-router <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name (e.g., `Profile`, `Notifications`)

## Output Location

```
Pulse/<FeatureName>/Router/<FeatureName>NavigationRouter.swift
```

## Template

```swift
import EntropyCore
import UIKit

// MARK: - Navigation Events

enum <FeatureName>NavigationEvent {
    case <entity>Detail(<Entity>)
    case settings
    case createNew
    case edit(<Entity>)
}

// MARK: - Navigation Router

@MainActor
final class <FeatureName>NavigationRouter: NavigationRouter, Equatable {
    // MARK: - Properties

    nonisolated(unsafe) var navigation: UINavigationController?
    private nonisolated(unsafe) weak var coordinator: Coordinator?

    // MARK: - Initialization

    init(coordinator: Coordinator? = nil) {
        self.coordinator = coordinator
    }

    // MARK: - NavigationRouter

    func route(navigationEvent: <FeatureName>NavigationEvent) {
        guard let coordinator else { return }

        switch navigationEvent {
        case let .<entity>Detail(entity):
            coordinator.push(page: .<entity>Detail(entity))

        case .settings:
            coordinator.push(page: .settings)

        case .createNew:
            coordinator.push(page: .create<Entity>)

        case let .edit(entity):
            coordinator.push(page: .edit<Entity>(entity))
        }
    }

    // MARK: - Equatable

    nonisolated static func == (lhs: <FeatureName>NavigationRouter, rhs: <FeatureName>NavigationRouter) -> Bool {
        lhs.coordinator === rhs.coordinator
    }
}
```

## Key Patterns

1. **Import `EntropyCore`** - For `NavigationRouter` protocol
2. **Use `@MainActor`** - Router operations happen on main thread
3. **Weak coordinator reference** - Prevents retain cycles
4. **Use `nonisolated(unsafe)`** - For weak references in actor isolation
5. **Conform to `Equatable`** - Required for SwiftUI view identity
6. **Guard on coordinator** - Gracefully handle nil coordinator

## Protocol Definition

```swift
// From EntropyCore
protocol NavigationRouter {
    var navigation: UINavigationController? { get set }
    func route(navigationEvent: /* feature-specific */)
}
```

## Navigation Event Patterns

### Detail Navigation
```swift
case entityDetail(Entity)  // Push detail view
```

### Modal Presentation
```swift
case createNew             // Present creation flow
case edit(Entity)          // Present edit flow
```

### Tab Switching
```swift
case switchToHome          // Coordinate with tabs
case switchToSearch(query: String)
```

### External Navigation
```swift
case openURL(URL)          // Open in Safari
case share(Entity)         // Present share sheet
```

## Coordinator Integration

The router delegates to Coordinator, which manages NavigationPath:

```swift
// In Coordinator.swift
func push(page: Page, in tab: AppTab? = nil) {
    let targetTab = tab ?? selectedTab
    switch targetTab {
    case .home:
        homePath.append(page)
    case .search:
        searchPath.append(page)
    // ...
    }
}
```

## Page Enum Update

After creating router, update `Page.swift`:

```swift
enum Page: Hashable {
    case articleDetail(Article)
    case settings
    // Add new cases:
    case <entity>Detail(<Entity>)
    case create<Entity>
    case edit<Entity>(<Entity>)
}
```

## Coordinator Build Update

Update `Coordinator.build(page:)`:

```swift
@ViewBuilder
func build(page: Page) -> some View {
    switch page {
    case let .<entity>Detail(entity):
        <Entity>DetailView(entity: entity, serviceLocator: serviceLocator)
    case .create<Entity>:
        Create<Entity>View(serviceLocator: serviceLocator)
    case let .edit<Entity>(entity):
        Edit<Entity>View(entity: entity, serviceLocator: serviceLocator)
    // ...
    }
}
```

## Mock Router for Testing

```swift
// In Tests/Mocks/
final class Mock<FeatureName>NavigationRouter: <FeatureName>NavigationRouter {
    var routedEvents: [<FeatureName>NavigationEvent] = []

    override func route(navigationEvent: <FeatureName>NavigationEvent) {
        routedEvents.append(navigationEvent)
    }
}
```

## Instructions

1. Ask what **destinations** the feature can navigate to
2. Create the NavigationEvent enum with appropriate cases
3. Create the router following the template
4. **Remind to update** `Page.swift` with new cases
5. **Remind to update** `Coordinator.build(page:)` with new views
