# Create UDF Feature

Creates a complete feature module using Unidirectional Data Flow Architecture. This skill orchestrates all component generation in the correct dependency order.

## Usage

```
/pulse:create-feature <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name for the feature (e.g., `Profile`, `Notifications`, `Comments`)

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  1. GATHER REQUIREMENTS                                         │
│     - Feature name, entity type, operations needed              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  2. CREATE FOLDER STRUCTURE                                     │
│     Pulse/<FeatureName>/                                        │
│     ├── API/                                                    │
│     ├── Domain/                                                 │
│     ├── ViewModel/                                              │
│     ├── ViewStates/                                             │
│     ├── ViewEvents/                                             │
│     ├── View/                                                   │
│     └── Router/                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  3. CREATE SERVICE LAYER (Bottom-up)                            │
│     - <FeatureName>Service.swift (protocol)                     │
│     - Live<FeatureName>Service.swift (implementation)           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  4. CREATE DOMAIN LAYER                                         │
│     - <FeatureName>DomainState.swift                            │
│     - <FeatureName>DomainAction.swift                           │
│     - <FeatureName>DomainInteractor.swift                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  5. CREATE PRESENTATION LAYER                                   │
│     - <FeatureName>ViewState.swift                              │
│     - <FeatureName>ViewEvent.swift                              │
│     - <FeatureName>EventActionMap.swift                         │
│     - <FeatureName>ViewStateReducer.swift                       │
│     - <FeatureName>ViewModel.swift                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  6. CREATE VIEW LAYER                                           │
│     - <FeatureName>NavigationRouter.swift                       │
│     - <FeatureName>View.swift                                   │
│     - <Entity>Card.swift (if needed)                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  7. INTEGRATION                                                 │
│     - Register service in PulseSceneDelegate                    │
│     - Add Page cases                                            │
│     - Update Coordinator                                        │
│     - Add to CoordinatorView (if tab)                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  8. CREATE TESTS (Optional)                                     │
│     - Mock<FeatureName>Service.swift                            │
│     - <FeatureName>DomainInteractorTests.swift                  │
│     - <FeatureName>ViewModelTests.swift                         │
└─────────────────────────────────────────────────────────────────┘
```

## Instructions

### Phase 1: Requirements Gathering

Ask the user for:

1. **Feature Name** (if not provided as argument)
   - Must be PascalCase (e.g., `Comments`, `UserProfile`, `Notifications`)

2. **Primary Entity Type**
   - What data model does this feature work with?
   - Examples: `Comment`, `User`, `Notification`, `Message`
   - Will this use an existing model or need a new one?

3. **Required Operations**
   - [ ] Load list (paginated)
   - [ ] Load single item
   - [ ] Create new
   - [ ] Update existing
   - [ ] Delete
   - [ ] Search/filter
   - [ ] Bookmark/favorite
   - [ ] Share

4. **Navigation Requirements**
   - What screens can be navigated TO from this feature?
   - Is this a tab or pushed view?
   - Does it need settings access?

5. **API Integration**
   - Does it use Guardian API or a new endpoint?
   - What's the API response format?

### Phase 2: Create Folder Structure

```bash
mkdir -p Pulse/<FeatureName>/{API,Domain,ViewModel,ViewStates,ViewEvents,View,Router}
```

### Phase 3: Create Service Layer

Use `/pulse:gen-service` pattern to create:

**File: `Pulse/<FeatureName>/API/<FeatureName>Service.swift`**
```swift
import Combine
import Foundation

protocol <FeatureName>Service {
    func fetch<Entity>s(page: Int) -> AnyPublisher<[<Entity>], Error>
    // Add other operations based on requirements
}
```

**File: `Pulse/<FeatureName>/API/Live<FeatureName>Service.swift`**
```swift
import Combine
import Foundation

final class Live<FeatureName>Service: APIRequest, <FeatureName>Service {
    func fetch<Entity>s(page: Int) -> AnyPublisher<[<Entity>], Error> {
        // Implementation
    }
}
```

### Phase 4: Create Domain Layer

Use `/pulse:gen-domain-state` pattern:

**File: `Pulse/<FeatureName>/Domain/<FeatureName>DomainState.swift`**
```swift
struct <FeatureName>DomainState: Equatable {
    var items: [<Entity>]
    var isLoading: Bool
    var isLoadingMore: Bool
    var isRefreshing: Bool
    var error: String?
    var currentPage: Int
    var hasMorePages: Bool
    var hasLoadedInitialData: Bool
    var selected<Entity>: <Entity>?

    static var initial: <FeatureName>DomainState { /* ... */ }
}
```

Use `/pulse:gen-domain-action` pattern:

**File: `Pulse/<FeatureName>/Domain/<FeatureName>DomainAction.swift`**
```swift
enum <FeatureName>DomainAction: Equatable {
    case loadInitialData
    case loadMore
    case refresh
    case select<Entity>(id: String)
    case clearSelected<Entity>
    // Add based on operations
}
```

Use `/pulse:gen-domain-interactor` pattern:

**File: `Pulse/<FeatureName>/Domain/<FeatureName>DomainInteractor.swift`**
```swift
final class <FeatureName>DomainInteractor: CombineInteractor {
    // Full implementation with service calls
}
```

### Phase 5: Create Presentation Layer

Use `/pulse:gen-view-state` pattern:

**File: `Pulse/<FeatureName>/ViewStates/<FeatureName>ViewState.swift`**
```swift
struct <FeatureName>ViewState: Equatable {
    var items: [<Entity>ViewItem]
    var isLoading: Bool
    // ... presentation-ready state
}

struct <Entity>ViewItem: Identifiable, Equatable {
    // Presentation model
}
```

Use `/pulse:gen-view-event` pattern:

**File: `Pulse/<FeatureName>/ViewEvents/<FeatureName>ViewEvent.swift`**
```swift
enum <FeatureName>ViewEvent: Equatable {
    case onAppear
    case onRefresh
    case onLoadMore
    case on<Entity>Tapped(id: String)
    case on<Entity>Navigated
}
```

Use `/pulse:gen-event-action-map` pattern:

**File: `Pulse/<FeatureName>/Domain/<FeatureName>EventActionMap.swift`**
```swift
struct <FeatureName>EventActionMap: DomainEventActionMap {
    func map(event: <FeatureName>ViewEvent) -> <FeatureName>DomainAction? {
        // Mapping logic
    }
}
```

Use `/pulse:gen-view-state-reducer` pattern:

**File: `Pulse/<FeatureName>/Domain/<FeatureName>ViewStateReducer.swift`**
```swift
struct <FeatureName>ViewStateReducer: ViewStateReducing {
    func reduce(domainState: <FeatureName>DomainState) -> <FeatureName>ViewState {
        // Transformation logic
    }
}
```

Use `/pulse:gen-viewmodel` pattern:

**File: `Pulse/<FeatureName>/ViewModel/<FeatureName>ViewModel.swift`**
```swift
@MainActor
final class <FeatureName>ViewModel: CombineViewModel, ObservableObject {
    // Full ViewModel implementation
}
```

### Phase 6: Create View Layer

Use `/pulse:gen-router` pattern:

**File: `Pulse/<FeatureName>/Router/<FeatureName>NavigationRouter.swift`**
```swift
enum <FeatureName>NavigationEvent {
    case <entity>Detail(<Entity>)
    case settings
}

@MainActor
final class <FeatureName>NavigationRouter: NavigationRouter, Equatable {
    // Router implementation
}
```

Use `/pulse:gen-view` pattern:

**File: `Pulse/<FeatureName>/View/<FeatureName>View.swift`**
```swift
struct <FeatureName>View<R: <FeatureName>NavigationRouter>: View {
    private var router: R
    @ObservedObject var viewModel: <FeatureName>ViewModel

    var body: some View {
        // View implementation
    }
}
```

### Phase 7: Integration

**Update `Pulse/Configs/Navigation/Page.swift`:**
```swift
enum Page: Hashable {
    // Existing cases...
    case <entity>Detail(<Entity>)
}
```

**Update `Pulse/Configs/Navigation/Coordinator.swift`:**
```swift
// Add path if new tab
@Published var <featureName>Path = NavigationPath()

// Add lazy ViewModel
lazy var <featureName>ViewModel: <FeatureName>ViewModel = .init(serviceLocator: serviceLocator)

// Update build(page:)
@ViewBuilder
func build(page: Page) -> some View {
    switch page {
    // Existing cases...
    case let .<entity>Detail(entity):
        <Entity>DetailView(entity: entity, serviceLocator: serviceLocator)
    }
}
```

**Update `PulseSceneDelegate.swift`:**
```swift
// Register service
serviceLocator.register(<FeatureName>Service.self, instance: Live<FeatureName>Service())
```

**If new tab, update `Pulse/Configs/Navigation/CoordinatorView.swift`:**
```swift
Tab("<FeatureName>", systemImage: "icon.name", value: .<featureName>) {
    NavigationStack(path: $coordinator.<featureName>Path) {
        <FeatureName>View(
            router: <FeatureName>NavigationRouter(coordinator: coordinator),
            viewModel: coordinator.<featureName>ViewModel
        )
        .navigationDestination(for: Page.self) { page in
            coordinator.build(page: page)
        }
    }
}
```

### Phase 8: Create Tests (Optional)

**File: `Pulse/Configs/Mocks/Mock<FeatureName>Service.swift`**
```swift
final class Mock<FeatureName>Service: <FeatureName>Service {
    var mock<Entity>s: [<Entity>] = []
    var mockError: Error?
    // Mock implementation
}
```

**File: `PulseTests/<FeatureName>/<FeatureName>DomainInteractorTests.swift`**
```swift
@testable import Pulse
import Testing

@Suite("<FeatureName>DomainInteractor Tests")
struct <FeatureName>DomainInteractorTests {
    // Test cases
}
```

## File Creation Order

Create files in this exact order to satisfy dependencies:

1. `<FeatureName>Service.swift` (protocol)
2. `Live<FeatureName>Service.swift` (implementation)
3. `<FeatureName>DomainState.swift`
4. `<FeatureName>DomainAction.swift`
5. `<FeatureName>DomainInteractor.swift`
6. `<FeatureName>ViewState.swift` (with ViewItem)
7. `<FeatureName>ViewEvent.swift`
8. `<FeatureName>EventActionMap.swift`
9. `<FeatureName>ViewStateReducer.swift`
10. `<FeatureName>ViewModel.swift`
11. `<FeatureName>NavigationRouter.swift`
12. `<FeatureName>View.swift`
13. Update `Page.swift`
14. Update `Coordinator.swift`
15. Update `PulseSceneDelegate.swift`
16. (Optional) `CoordinatorView.swift` if tab
17. (Optional) Mock + Tests

## Checklist

After feature creation, verify:

- [ ] All files compile without errors
- [ ] Service is registered in ServiceLocator
- [ ] Page cases added for navigation
- [ ] Coordinator has path and ViewModel
- [ ] Router correctly maps to Coordinator
- [ ] View binds to ViewModel properly
- [ ] Navigation works (push/pop)
- [ ] Pull-to-refresh works
- [ ] Pagination works
- [ ] Error states display correctly
- [ ] Empty state displays correctly
- [ ] Loading states display correctly

## Example: Creating a "Comments" Feature

```
/pulse:create-feature Comments
```

This would create:
- `CommentsService` protocol with `fetchComments(articleId:page:)`
- `LiveCommentsService` with Guardian API integration
- `CommentsDomainState` with comments, loading states, pagination
- `CommentsDomainAction` with load, refresh, reply, delete actions
- `CommentsDomainInteractor` with business logic
- `CommentsViewState` with `CommentViewItem` transformation
- `CommentsViewEvent` for user interactions
- `CommentsEventActionMap` for event mapping
- `CommentsViewStateReducer` for state transformation
- `CommentsViewModel` wiring everything together
- `CommentsNavigationRouter` for navigation
- `CommentsView` with comment list UI
- Integration with existing navigation
