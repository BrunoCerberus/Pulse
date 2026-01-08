# Generate DomainState

Creates a DomainState struct for business-layer data.

## Usage

```
/pulse:gen-domain-state <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name (e.g., `Profile`, `Notifications`)

## Output Location

```
Pulse/<FeatureName>/Domain/<FeatureName>DomainState.swift
```

## Template

```swift
import Foundation

struct <FeatureName>DomainState: Equatable {
    // MARK: - Data Properties
    var items: [<Entity>]

    // MARK: - Loading States
    var isLoading: Bool
    var isLoadingMore: Bool
    var isRefreshing: Bool

    // MARK: - Error State
    var error: String?

    // MARK: - Pagination
    var currentPage: Int
    var hasMorePages: Bool
    var hasLoadedInitialData: Bool

    // MARK: - Selection State
    var selected<Entity>: <Entity>?

    // MARK: - Action State
    var <entity>ToShare: <Entity>?

    // MARK: - Initial State
    static var initial: <FeatureName>DomainState {
        <FeatureName>DomainState(
            items: [],
            isLoading: false,
            isLoadingMore: false,
            isRefreshing: false,
            error: nil,
            currentPage: 1,
            hasMorePages: true,
            hasLoadedInitialData: false,
            selected<Entity>: nil,
            <entity>ToShare: nil
        )
    }
}
```

## Key Patterns

1. **Always conform to `Equatable`** - Required for Combine state diffing
2. **Use raw domain entities** - Not presentation-ready ViewItems
3. **Track pagination state** - `currentPage`, `hasMorePages`, `hasLoadedInitialData`
4. **Include action targets** - `itemToShare`, `itemToDelete` for pending actions
5. **Provide `static var initial`** - Default state for Interactor initialization

## Domain vs View State

| Aspect | DomainState | ViewState |
|--------|-------------|-----------|
| Entity type | Raw `Article` | `ArticleViewItem` |
| Error format | Technical string | User-friendly message |
| Pagination | `currentPage`, `hasMorePages` | None (hidden from UI) |
| Computed flags | None | `showEmptyState`, `showOnboarding` |

## Common Properties

### Data Properties
```swift
var items: [Entity]
var featuredItems: [Entity]
var recentItems: [Entity]
```

### Loading States
```swift
var isLoading: Bool          // Initial load
var isLoadingMore: Bool      // Pagination
var isRefreshing: Bool       // Pull-to-refresh
var isSorting: Bool          // Re-sorting data
```

### Pagination
```swift
var currentPage: Int
var hasMorePages: Bool
var hasLoadedInitialData: Bool
var totalItems: Int?
```

### Selection & Actions
```swift
var selectedEntity: Entity?
var entityToShare: Entity?
var entityToDelete: Entity?
```

### Filter/Sort State
```swift
var sortOption: SortOption
var filterOptions: Set<FilterOption>
var searchQuery: String
```

## Instructions

1. Ask for the **entity type** the feature manages
2. Ask about **pagination requirements**
3. Ask about **filter/sort options** needed
4. Ask about **action states** (share, delete, edit)
5. Create the file following the template
