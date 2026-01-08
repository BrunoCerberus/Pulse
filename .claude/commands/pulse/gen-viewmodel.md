# Generate ViewModel

Creates a ViewModel with presentation logic and state binding.

## Usage

```
/pulse:gen-viewmodel <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name (e.g., `Profile`, `Notifications`)

## Output Location

```
Pulse/<FeatureName>/ViewModel/<FeatureName>ViewModel.swift
```

## Template (Full Pattern with Separate Reducer/EventMap)

```swift
import Combine
import Foundation

@MainActor
final class <FeatureName>ViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = <FeatureName>ViewState
    typealias ViewEvent = <FeatureName>ViewEvent

    // MARK: - Published State

    @Published private(set) var viewState: <FeatureName>ViewState = .initial

    // MARK: - Dependencies

    private let serviceLocator: ServiceLocator
    private let interactor: <FeatureName>DomainInteractor
    private let reducer: <FeatureName>ViewStateReducer
    private let eventMap: <FeatureName>EventActionMap
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        serviceLocator: ServiceLocator,
        reducer: <FeatureName>ViewStateReducer = <FeatureName>ViewStateReducer(),
        eventMap: <FeatureName>EventActionMap = <FeatureName>EventActionMap()
    ) {
        self.serviceLocator = serviceLocator
        interactor = <FeatureName>DomainInteractor(serviceLocator: serviceLocator)
        self.reducer = reducer
        self.eventMap = eventMap
        setupBindings()
    }

    // MARK: - CombineViewModel

    func handle(event: <FeatureName>ViewEvent) {
        guard let action = eventMap.map(event: event) else { return }
        interactor.dispatch(action: action)
    }

    // MARK: - Private

    private func setupBindings() {
        interactor.statePublisher
            .map { [reducer] state in reducer.reduce(domainState: state) }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
```

## Template (Simplified Pattern with Inline Reducer/EventMap)

```swift
import Combine
import Foundation

@MainActor
final class <FeatureName>ViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = <FeatureName>ViewState
    typealias ViewEvent = <FeatureName>ViewEvent

    // MARK: - Published State

    @Published private(set) var viewState: <FeatureName>ViewState = .initial

    // MARK: - Dependencies

    private let serviceLocator: ServiceLocator
    private let interactor: <FeatureName>DomainInteractor
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        interactor = <FeatureName>DomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
    }

    // MARK: - CombineViewModel

    func handle(event: <FeatureName>ViewEvent) {
        // Inline EventActionMap
        switch event {
        case .onAppear:
            interactor.dispatch(action: .loadInitialData)
        case .onRefresh:
            interactor.dispatch(action: .refresh)
        case .onLoadMore:
            interactor.dispatch(action: .loadMore)
        case let .on<Entity>Tapped(id):
            interactor.dispatch(action: .select<Entity>(id: id))
        case .on<Entity>Navigated:
            interactor.dispatch(action: .clearSelected<Entity>)
        }
    }

    // MARK: - Private

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                // Inline ViewStateReducer
                <FeatureName>ViewState(
                    items: state.items.map { <Entity>ViewItem(from: $0) },
                    isLoading: state.isLoading,
                    isLoadingMore: state.isLoadingMore,
                    isRefreshing: state.isRefreshing,
                    errorMessage: state.error,
                    showEmptyState: !state.isLoading && !state.isRefreshing && state.items.isEmpty,
                    selected<Entity>: state.selected<Entity>
                )
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
```

## Template (With Debounced Search)

```swift
import Combine
import Foundation

@MainActor
final class <FeatureName>ViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = <FeatureName>ViewState
    typealias ViewEvent = <FeatureName>ViewEvent

    @Published private(set) var viewState: <FeatureName>ViewState = .initial

    private let serviceLocator: ServiceLocator
    private let interactor: <FeatureName>DomainInteractor
    private var cancellables = Set<AnyCancellable>()
    private let searchQuerySubject = PassthroughSubject<String, Never>()

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        interactor = <FeatureName>DomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
        setupDebouncedSearch()
    }

    func handle(event: <FeatureName>ViewEvent) {
        switch event {
        case let .onQueryChanged(query):
            interactor.dispatch(action: .updateQuery(query))
            searchQuerySubject.send(query)
        case .onSearch:
            interactor.dispatch(action: .search)
        // ... other events
        }
    }

    private func setupDebouncedSearch() {
        searchQuerySubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .filter { !$0.isEmpty }
            .sink { [weak self] _ in
                self?.interactor.dispatch(action: .search)
            }
            .store(in: &cancellables)
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in /* reduce to ViewState */ }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
```

## Key Patterns

1. **Use `@MainActor`** - Required for UI thread safety
2. **Conform to `CombineViewModel` + `ObservableObject`** - For SwiftUI binding
3. **Use `@Published private(set)`** - Read-only viewState for views
4. **Use `.removeDuplicates()`** - Prevent redundant view updates
5. **Use `assign(to: &$viewState)`** - Modern Combine assignment

## Protocol Definition

```swift
// From Configs/Extensions/CombineViewModel.swift
protocol CombineViewModel: ObservableObject {
    associatedtype ViewState: Equatable
    associatedtype ViewEvent

    var viewState: ViewState { get }
    func handle(event: ViewEvent)
}
```

## Pattern Choice

| Pattern | Use When |
|---------|----------|
| **Full (separate files)** | Complex features, need testable components |
| **Simplified (inline)** | Simple features, straightforward mappings |
| **With debounce** | Search, autocomplete, real-time filtering |

## Binding Pipeline

```
Interactor.statePublisher
    → .map { reducer.reduce(domainState:) }  // Transform to ViewState
    → .removeDuplicates()                     // Skip identical states
    → .receive(on: DispatchQueue.main)        // Ensure main thread
    → .assign(to: &$viewState)                // Update published property
```

## Instructions

1. **Require DomainInteractor exists** - Must exist first
2. Ask if **separate Reducer/EventMap** or inline
3. Ask about **debounced inputs** (search, filtering)
4. Create the file following appropriate template
5. Wire up all event handling and state bindings
