# Generate ViewStateReducer

Creates a ViewStateReducer that transforms DomainState to ViewState.

## Usage

```
/pulse:gen-view-state-reducer <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name (e.g., `Profile`, `Notifications`)

## Output Location

```
Pulse/<FeatureName>/Domain/<FeatureName>ViewStateReducer.swift
```

## Template

```swift
import Foundation

struct <FeatureName>ViewStateReducer: ViewStateReducing {
    func reduce(domainState: <FeatureName>DomainState) -> <FeatureName>ViewState {
        <FeatureName>ViewState(
            // Transform entities to view items
            items: domainState.items.map { <Entity>ViewItem(from: $0) },

            // Pass through loading states
            isLoading: domainState.isLoading,
            isLoadingMore: domainState.isLoadingMore,
            isRefreshing: domainState.isRefreshing,

            // Transform error (could localize here)
            errorMessage: domainState.error,

            // Compute UI flags
            showEmptyState: !domainState.isLoading
                && !domainState.isRefreshing
                && domainState.items.isEmpty,

            // Pass through selection
            selected<Entity>: domainState.selected<Entity>,

            // Pass through action targets
            <entity>ToShare: domainState.<entity>ToShare
        )
    }
}
```

## Key Patterns

1. **Conform to `ViewStateReducing`** - Protocol from Extensions
2. **Transform entities to ViewItems** - Use `.map { ViewItem(from: $0) }`
3. **Compute derived UI state** - `showEmptyState`, `showOnboarding`
4. **Keep as pure function** - No side effects, no dependencies
5. **Don't expose pagination details** - Hide `currentPage`, `hasMorePages`

## Protocol Definition

```swift
// From Configs/Extensions/ViewStateReducing.swift
protocol ViewStateReducing {
    associatedtype DomainState
    associatedtype ViewState

    func reduce(domainState: DomainState) -> ViewState
}
```

## Transformation Patterns

### Entity to ViewItem
```swift
items: domainState.articles.map { ArticleViewItem(from: $0) }
```

### Computed Empty State
```swift
showEmptyState: !domainState.isLoading
    && !domainState.isRefreshing
    && domainState.items.isEmpty
```

### Computed Onboarding State
```swift
showOnboarding: domainState.preferences.followedTopics.isEmpty
    && !domainState.isLoading
    && !domainState.isRefreshing
```

### Error Transformation
```swift
// Simple pass-through
errorMessage: domainState.error

// With localization
errorMessage: domainState.error.map { LocalizedError.message(for: $0) }
```

### Conditional Properties
```swift
// Only show when not loading
showResults: !domainState.isLoading && domainState.hasSearched
```

## Inline Alternative

For simpler features, the reducer can be inline in ViewModel's `setupBindings`:

```swift
private func setupBindings() {
    interactor.statePublisher
        .map { state in
            <FeatureName>ViewState(
                items: state.items.map { <Entity>ViewItem(from: $0) },
                isLoading: state.isLoading,
                // ... rest of transformation
            )
        }
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .assign(to: &$viewState)
}
```

## Domain vs View State Transformations

| DomainState | ViewState | Transformation |
|-------------|-----------|----------------|
| `[Article]` | `[ArticleViewItem]` | Map to presentation type |
| `error: String?` | `errorMessage: String?` | Could localize |
| `isLoading + items.isEmpty` | `showEmptyState: Bool` | Compute derived |
| `currentPage`, `hasMorePages` | (hidden) | Not exposed to UI |
| `preferences.followedTopics` | `showOnboarding: Bool` | Compute derived |

## Instructions

1. **Require existing DomainState and ViewState** - Must exist first
2. Create the reducer following the template
3. Map entities to ViewItems
4. Compute derived UI flags
5. Hide pagination/internal state from ViewState
