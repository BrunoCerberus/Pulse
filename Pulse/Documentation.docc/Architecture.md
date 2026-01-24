# Architecture

Understanding the Unidirectional Data Flow architecture in Pulse.

## Overview

Pulse uses a Unidirectional Data Flow (UDF) architecture inspired by Clean Architecture.
This ensures predictable state management, testability, and separation of concerns.

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│  View (SwiftUI)                                             │
│  @ObservedObject viewModel                                  │
└─────────────────────────────────────────────────────────────┘
       │ handle(event: ViewEvent)           ↑ @Published viewState
       ↓                                    │
┌─────────────────────────────────────────────────────────────┐
│  ViewModel (CombineViewModel)                               │
│  - EventActionMap: ViewEvent → DomainAction                 │
│  - Reducer: DomainState → ViewState                         │
└─────────────────────────────────────────────────────────────┘
       │ dispatch(action:)                  ↑ statePublisher
       ↓                                    │
┌─────────────────────────────────────────────────────────────┐
│  DomainInteractor (CombineInteractor)                       │
│  - CurrentValueSubject<DomainState, Never>                  │
│  - Business logic + state mutations                         │
└─────────────────────────────────────────────────────────────┘
       │                                    ↑
       ↓                                    │
┌─────────────────────────────────────────────────────────────┐
│  Service Layer (Protocol-based)                             │
└─────────────────────────────────────────────────────────────┘
```

## Core Protocols

### CombineViewModel

The ViewModel protocol defines the contract for presentation-layer components:

```swift
protocol CombineViewModel: ObservableObject {
    associatedtype ViewState: Equatable
    associatedtype ViewEvent
    var viewState: ViewState { get }
    func handle(event: ViewEvent)
}
```

### CombineInteractor

The Interactor protocol defines the contract for domain-layer components:

```swift
protocol CombineInteractor {
    associatedtype DomainState: Equatable
    associatedtype DomainAction
    var statePublisher: AnyPublisher<DomainState, Never> { get }
    func dispatch(action: DomainAction)
}
```

### ViewStateReducing

Transforms domain state to view state:

```swift
protocol ViewStateReducing {
    associatedtype DomainState
    associatedtype ViewState
    func reduce(domainState: DomainState) -> ViewState
}
```

### DomainEventActionMap

Maps UI events to domain actions:

```swift
protocol DomainEventActionMap {
    associatedtype ViewEvent
    associatedtype DomainAction
    func map(event: ViewEvent) -> DomainAction?
}
```

## Dependency Injection

Pulse uses `ServiceLocator` for dependency injection:

```swift
// Registration (PulseSceneDelegate)
let serviceLocator = ServiceLocator()
serviceLocator.register(NewsService.self, instance: LiveNewsService())

// Retrieval (in Interactors)
let newsService = try serviceLocator.retrieve(NewsService.self)
```

## Navigation

Navigation is handled by a central `Coordinator` with per-tab `NavigationPath`:

```swift
@MainActor
final class Coordinator: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var homePath = NavigationPath()
    // ... other tab paths

    func push(page: Page, in tab: AppTab? = nil)
    func pop()
    func popToRoot(in tab: AppTab? = nil)
}
```

Views are generic over router types for testability:

```swift
struct HomeView<R: HomeNavigationRouter>: View {
    private var router: R
    @ObservedObject var viewModel: HomeViewModel
}
```

## Testing

Each layer is independently testable:

- **ViewModels**: Test with mock interactors
- **Interactors**: Test with mock services
- **Services**: Test with mock network/storage

```swift
// Test setup
let mockService = MockNewsService()
let serviceLocator = ServiceLocator()
serviceLocator.register(NewsService.self, instance: mockService)
let interactor = HomeDomainInteractor(serviceLocator: serviceLocator)
```
