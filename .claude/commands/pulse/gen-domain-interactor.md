# Generate DomainInteractor

Creates a DomainInteractor with business logic and state management.

## Usage

```
/pulse:gen-domain-interactor <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name (e.g., `Profile`, `Notifications`)

## Output Location

```
Pulse/<FeatureName>/Domain/<FeatureName>DomainInteractor.swift
```

## Template

```swift
import Combine
import Foundation

final class <FeatureName>DomainInteractor: CombineInteractor {
    typealias DomainState = <FeatureName>DomainState
    typealias DomainAction = <FeatureName>DomainAction

    // MARK: - Dependencies

    private let <featureName>Service: <FeatureName>Service
    private let storageService: StorageService

    // MARK: - State Management

    private let stateSubject = CurrentValueSubject<<FeatureName>DomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTasks = Set<Task<Void, Never>>()

    // MARK: - Public Properties

    var statePublisher: AnyPublisher<<FeatureName>DomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: <FeatureName>DomainState {
        stateSubject.value
    }

    // MARK: - Initialization

    init(serviceLocator: ServiceLocator) {
        do {
            <featureName>Service = try serviceLocator.retrieve(<FeatureName>Service.self)
        } catch {
            Logger.shared.service("Failed to retrieve <FeatureName>Service: \(error)", level: .warning)
            <featureName>Service = Live<FeatureName>Service()
        }

        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }
    }

    deinit {
        backgroundTasks.forEach { $0.cancel() }
        backgroundTasks.removeAll()
    }

    // MARK: - Action Dispatch

    func dispatch(action: <FeatureName>DomainAction) {
        switch action {
        case .loadInitialData:
            loadInitialData()
        case .loadMore:
            loadMore()
        case .refresh:
            refresh()
        case let .select<Entity>(id):
            select<Entity>(id: id)
        case .clearSelected<Entity>:
            updateState { $0.selected<Entity> = nil }
        case let .bookmark<Entity>(id):
            bookmark<Entity>(id: id)
        case let .share<Entity>(id):
            share<Entity>(id: id)
        case .clear<Entity>ToShare:
            updateState { $0.<entity>ToShare = nil }
        }
    }

    // MARK: - State Update Helper

    private func updateState(_ transform: (inout <FeatureName>DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }

    // MARK: - Data Loading

    private func loadInitialData() {
        guard !currentState.hasLoadedInitialData else { return }
        updateState { $0.isLoading = true }

        <featureName>Service.fetch<Entity>s(page: 1)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.updateState {
                            $0.isLoading = false
                            $0.error = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] items in
                    self?.updateState {
                        $0.items = items
                        $0.isLoading = false
                        $0.hasLoadedInitialData = true
                        $0.currentPage = 1
                        $0.hasMorePages = !items.isEmpty
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func loadMore() {
        guard !currentState.isLoadingMore,
              !currentState.isLoading,
              currentState.hasMorePages else { return }

        let nextPage = currentState.currentPage + 1
        updateState { $0.isLoadingMore = true }

        <featureName>Service.fetch<Entity>s(page: nextPage)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.updateState {
                            $0.isLoadingMore = false
                            $0.error = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] items in
                    self?.updateState {
                        $0.items.append(contentsOf: items)
                        $0.isLoadingMore = false
                        $0.currentPage = nextPage
                        $0.hasMorePages = !items.isEmpty
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func refresh() {
        updateState {
            $0.isRefreshing = true
            $0.error = nil
        }

        <featureName>Service.fetch<Entity>s(page: 1)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.updateState {
                            $0.isRefreshing = false
                            $0.error = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] items in
                    self?.updateState {
                        $0.items = items
                        $0.isRefreshing = false
                        $0.currentPage = 1
                        $0.hasMorePages = true
                    }
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Selection

    private func select<Entity>(id: String) {
        guard let item = currentState.items.first(where: { $0.id == id }) else { return }
        updateState { $0.selected<Entity> = item }
    }

    // MARK: - Actions

    private func bookmark<Entity>(id: String) {
        guard let item = currentState.items.first(where: { $0.id == id }) else { return }

        let task = Task { @MainActor in
            do {
                try await storageService.saveBookmark(item)
                HapticManager.shared.notification(type: .success)
            } catch {
                Logger.shared.storage("Failed to bookmark: \(error)", level: .error)
                updateState { $0.error = "Failed to save bookmark" }
            }
        }
        backgroundTasks.insert(task)
    }

    private func share<Entity>(id: String) {
        guard let item = currentState.items.first(where: { $0.id == id }) else { return }
        updateState { $0.<entity>ToShare = item }
    }
}
```

## Key Patterns

1. **Conform to `CombineInteractor`** - Protocol from Extensions
2. **Use `CurrentValueSubject`** - For reactive state management
3. **Inject via ServiceLocator** - With fallback to Live implementations
4. **Cleanup in `deinit`** - Cancel background tasks
5. **Use `updateState` helper** - Thread-safe state mutations

## Protocol Definition

```swift
// From Configs/Extensions/CombineInteractor.swift
protocol CombineInteractor {
    associatedtype DomainState: Equatable
    associatedtype DomainAction

    var statePublisher: AnyPublisher<DomainState, Never> { get }
    func dispatch(action: DomainAction)
}
```

## State Update Pattern

```swift
private func updateState(_ transform: (inout <FeatureName>DomainState) -> Void) {
    var state = stateSubject.value
    transform(&state)
    stateSubject.send(state)
}
```

## Combine vs Task Patterns

### Use Combine For
- Service calls that return publishers
- Chained/composed operations
- Debounced inputs

### Use Task For
- Fire-and-forget operations (bookmarking)
- Operations that need async/await
- Cancellable background work

## Guard Patterns

```swift
// Prevent duplicate initial loads
guard !currentState.hasLoadedInitialData else { return }

// Prevent concurrent pagination
guard !currentState.isLoadingMore, currentState.hasMorePages else { return }

// Validate entity exists
guard let item = currentState.items.first(where: { $0.id == id }) else { return }
```

## Instructions

1. **Require existing DomainState and DomainAction** - Must exist first
2. Ask what **services** the interactor needs
3. Ask about **async operations** (Combine publishers vs Tasks)
4. Create the file following the template
5. Implement each action case with appropriate business logic
