# Generate ViewEvent

Creates a ViewEvent enum for user interactions.

## Usage

```
/pulse:gen-view-event <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name (e.g., `Profile`, `Notifications`)

## Output Location

```
Pulse/<FeatureName>/ViewEvents/<FeatureName>ViewEvent.swift
```

## Template

```swift
import Foundation

enum <FeatureName>ViewEvent: Equatable {
    // MARK: - Lifecycle Events
    case onAppear
    case onDisappear

    // MARK: - Data Loading Events
    case onRefresh
    case onLoadMore

    // MARK: - User Interaction Events
    case on<Entity>Tapped(id: String)
    case on<Entity>Navigated

    // MARK: - Action Events
    case onBookmarkTapped(id: String)
    case onShareTapped(id: String)
    case onDeleteTapped(id: String)

    // MARK: - Dismissal Events
    case onShareDismissed
    case onErrorDismissed
}
```

## Key Patterns

1. **Always conform to `Equatable`** - Required for testing and comparison
2. **Use `on` prefix** - Consistent naming convention
3. **Include associated values** - Pass IDs, not full objects
4. **Pair tapped/navigated events** - For clearing selection after navigation
5. **Group by category** - Lifecycle, loading, interaction, action, dismissal

## Common Event Categories

### Lifecycle Events
```swift
case onAppear
case onDisappear
```

### Data Loading Events
```swift
case onRefresh
case onLoadMore
case onRetry
```

### Selection Events
```swift
case on<Entity>Tapped(id: String)
case on<Entity>Navigated      // Called after navigation completes
case on<Entity>Selected(id: String)
case on<Entity>Deselected
```

### Action Events
```swift
case onBookmarkTapped(id: String)
case onShareTapped(id: String)
case onDeleteTapped(id: String)
case onEditTapped(id: String)
```

### Input Events
```swift
case onQueryChanged(String)
case onFilterChanged(FilterOption)
case onSortChanged(SortOption)
```

### Dismissal Events
```swift
case onShareDismissed
case onAlertDismissed
case onSheetDismissed
```

## Instructions

1. Ask what **user interactions** the view needs to handle
2. Ask about **navigation events** (what screens can be navigated to)
3. Ask about **action events** (bookmark, share, delete, etc.)
4. Create the file following the template
5. Use `id: String` for entity references, not the full entity
