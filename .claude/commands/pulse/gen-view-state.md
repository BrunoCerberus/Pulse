# Generate ViewState

Creates a ViewState struct for presentation-layer data.

## Usage

```
/pulse:gen-view-state <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name (e.g., `Profile`, `Notifications`)

## Output Location

```
Pulse/<FeatureName>/ViewStates/<FeatureName>ViewState.swift
```

## Template

```swift
import Foundation

struct <FeatureName>ViewState: Equatable {
    // MARK: - Data Properties
    var items: [<Entity>ViewItem]

    // MARK: - Loading States
    var isLoading: Bool
    var isLoadingMore: Bool
    var isRefreshing: Bool

    // MARK: - Error State
    var errorMessage: String?

    // MARK: - UI State
    var showEmptyState: Bool

    // MARK: - Selection State
    var selected<Entity>: <Entity>?

    // MARK: - Initial State
    static var initial: <FeatureName>ViewState {
        <FeatureName>ViewState(
            items: [],
            isLoading: false,
            isLoadingMore: false,
            isRefreshing: false,
            errorMessage: nil,
            showEmptyState: false,
            selected<Entity>: nil
        )
    }
}

// MARK: - View Item

struct <Entity>ViewItem: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let imageURL: URL?
    let formattedDate: String

    init(from entity: <Entity>) {
        id = entity.id
        title = entity.title
        description = entity.description
        imageURL = entity.imageURL
        formattedDate = entity.publishedAt?.formatted(.relative(presentation: .named)) ?? ""
    }
}
```

## Key Patterns

1. **Always conform to `Equatable`** - Required for SwiftUI diffing
2. **Use ViewItem types** - Transform domain entities to presentation-ready data
3. **Include UI state flags** - `showEmptyState`, `showOnboarding`, etc.
4. **Provide `static var initial`** - Default state for ViewModel initialization
5. **Keep properties presentation-focused** - Formatted strings, URLs, display flags

## Common Properties

| Property | Type | Purpose |
|----------|------|---------|
| `items` | `[ViewItem]` | Main data collection |
| `isLoading` | `Bool` | Initial load indicator |
| `isLoadingMore` | `Bool` | Pagination indicator |
| `isRefreshing` | `Bool` | Pull-to-refresh indicator |
| `errorMessage` | `String?` | User-facing error text |
| `showEmptyState` | `Bool` | No data indicator |
| `selectedItem` | `Entity?` | For navigation triggering |

## Instructions

1. Ask for the **entity type** the feature displays
2. Ask what **additional state properties** are needed
3. Create the file following the template
4. Create matching ViewItem if entity transformation needed
