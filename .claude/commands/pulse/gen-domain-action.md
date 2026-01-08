# Generate DomainAction

Creates a DomainAction enum for business operations.

## Usage

```
/pulse:gen-domain-action <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name (e.g., `Profile`, `Notifications`)

## Output Location

```
Pulse/<FeatureName>/Domain/<FeatureName>DomainAction.swift
```

## Template

```swift
import Foundation

enum <FeatureName>DomainAction: Equatable {
    // MARK: - Data Loading Actions
    case loadInitialData
    case loadMore
    case refresh

    // MARK: - Selection Actions
    case select<Entity>(id: String)
    case clearSelected<Entity>

    // MARK: - CRUD Actions
    case create<Entity>(<Entity>)
    case update<Entity>(<Entity>)
    case delete<Entity>(id: String)

    // MARK: - Action Triggers
    case bookmark<Entity>(id: String)
    case share<Entity>(id: String)
    case clear<Entity>ToShare

    // MARK: - Filter/Sort Actions
    case setFilter(FilterOption)
    case setSortOption(SortOption)
    case clearFilters
}
```

## Key Patterns

1. **Always conform to `Equatable`** - Required for testing
2. **Use imperative naming** - `loadInitialData`, not `onLoadInitialData`
3. **Pass IDs for entity actions** - `selectEntity(id:)`, not `selectEntity(_:)`
4. **Pair set/clear actions** - `shareEntity` + `clearEntityToShare`
5. **Keep actions atomic** - One action = one state change

## Domain vs View Events

| ViewEvent | DomainAction |
|-----------|--------------|
| `onAppear` | `loadInitialData` |
| `onRefresh` | `refresh` |
| `onLoadMore` | `loadMore` |
| `onArticleTapped(id:)` | `selectArticle(id:)` |
| `onArticleNavigated` | `clearSelectedArticle` |

## Common Action Categories

### Data Loading
```swift
case loadInitialData
case loadMore
case refresh
case retry
```

### Selection
```swift
case select<Entity>(id: String)
case clearSelected<Entity>
```

### CRUD Operations
```swift
case create<Entity>(<Entity>)
case update<Entity>(<Entity>)
case delete<Entity>(id: String)
case confirmDelete(id: String)
```

### Action Triggers
```swift
case bookmark<Entity>(id: String)
case unbookmark<Entity>(id: String)
case share<Entity>(id: String)
case clear<Entity>ToShare
```

### Filter/Sort
```swift
case setFilter(FilterOption)
case removeFilter(FilterOption)
case setSortOption(SortOption)
case clearFilters
case updateQuery(String)
case search
```

### State Updates
```swift
case setPreferences(UserPreferences)
case toggleSetting(SettingKey)
case reset
```

## Instructions

1. Ask what **data operations** the feature needs (load, create, update, delete)
2. Ask about **selection behavior** for navigation
3. Ask about **additional actions** (bookmark, share, etc.)
4. Ask about **filter/sort requirements**
5. Create the file following the template
