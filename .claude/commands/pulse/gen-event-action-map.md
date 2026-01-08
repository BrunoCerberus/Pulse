# Generate EventActionMap

Creates an EventActionMap struct that maps ViewEvents to DomainActions.

## Usage

```
/pulse:gen-event-action-map <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name (e.g., `Profile`, `Notifications`)

## Output Location

```
Pulse/<FeatureName>/Domain/<FeatureName>EventActionMap.swift
```

## Template

```swift
import Foundation

struct <FeatureName>EventActionMap: DomainEventActionMap {
    func map(event: <FeatureName>ViewEvent) -> <FeatureName>DomainAction? {
        switch event {
        // MARK: - Lifecycle Events
        case .onAppear:
            return .loadInitialData
        case .onDisappear:
            return nil  // No action needed

        // MARK: - Data Loading Events
        case .onRefresh:
            return .refresh
        case .onLoadMore:
            return .loadMore

        // MARK: - User Interaction Events
        case let .on<Entity>Tapped(id):
            return .select<Entity>(id: id)
        case .on<Entity>Navigated:
            return .clearSelected<Entity>

        // MARK: - Action Events
        case let .onBookmarkTapped(id):
            return .bookmark<Entity>(id: id)
        case let .onShareTapped(id):
            return .share<Entity>(id: id)

        // MARK: - Dismissal Events
        case .onShareDismissed:
            return .clear<Entity>ToShare
        case .onErrorDismissed:
            return nil  // Just dismiss UI
        }
    }
}
```

## Key Patterns

1. **Conform to `DomainEventActionMap`** - Protocol from Extensions
2. **Return `nil` for no-action events** - Some events don't need domain handling
3. **Direct 1:1 mapping preferred** - Keep transformation simple
4. **Extract associated values** - `case let .event(value)` syntax
5. **Keep as pure function** - No side effects, no dependencies

## Protocol Definition

```swift
// From Configs/Extensions/DomainEventActionMap.swift
protocol DomainEventActionMap {
    associatedtype ViewEvent
    associatedtype DomainAction

    func map(event: ViewEvent) -> DomainAction?
}
```

## Common Mappings

| ViewEvent | DomainAction |
|-----------|--------------|
| `onAppear` | `loadInitialData` |
| `onRefresh` | `refresh` |
| `onLoadMore` | `loadMore` |
| `on<Entity>Tapped(id:)` | `select<Entity>(id:)` |
| `on<Entity>Navigated` | `clearSelected<Entity>` |
| `onBookmarkTapped(id:)` | `bookmark<Entity>(id:)` |
| `onShareTapped(id:)` | `share<Entity>(id:)` |
| `onShareDismissed` | `clear<Entity>ToShare` |
| `onQueryChanged(query)` | `updateQuery(query)` |
| `onSearch` | `search` |
| `onSortChanged(option)` | `setSortOption(option)` |
| `onDisappear` | `nil` |
| `onErrorDismissed` | `nil` |

## When to Return nil

Return `nil` when the event:
- Is purely UI-related (dismissing an alert)
- Doesn't affect domain state
- Is handled entirely in the View layer

```swift
case .onDisappear:
    return nil  // Lifecycle, no domain action needed

case .onErrorDismissed:
    return nil  // UI dismissal only

case .onAnimationComplete:
    return nil  // Visual only
```

## Inline Alternative

For simpler features, the mapping can be inline in ViewModel:

```swift
func handle(event: <FeatureName>ViewEvent) {
    switch event {
    case .onAppear:
        interactor.dispatch(action: .loadInitialData)
    case .onRefresh:
        interactor.dispatch(action: .refresh)
    // ...
    }
}
```

## Instructions

1. **Require existing ViewEvent and DomainAction** - Must exist first
2. Create the mapping following the template
3. Return `nil` for events that don't need domain handling
4. Keep mappings simple and direct
