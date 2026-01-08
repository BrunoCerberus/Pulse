# Scaffold Feature

Creates a complete feature module with all UDF architecture components.

## Usage

```
/pulse:scaffold-feature <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name for the feature (e.g., `Profile`, `Notifications`)

## What Gets Created

```
Pulse/<FeatureName>/
├── API/
│   ├── <FeatureName>Service.swift       # Service protocol
│   └── Live<FeatureName>Service.swift   # Live implementation
├── Domain/
│   ├── <FeatureName>DomainState.swift   # Domain state struct
│   ├── <FeatureName>DomainAction.swift  # Domain actions enum
│   ├── <FeatureName>DomainInteractor.swift # Business logic
│   ├── <FeatureName>EventActionMap.swift   # Event to action mapping
│   └── <FeatureName>ViewStateReducer.swift # State transformation
├── ViewModel/
│   └── <FeatureName>ViewModel.swift     # Presentation logic
├── ViewStates/
│   └── <FeatureName>ViewState.swift     # View state struct
├── ViewEvents/
│   └── <FeatureName>ViewEvent.swift     # View events enum
├── View/
│   └── <FeatureName>View.swift          # SwiftUI view
└── Router/
    └── <FeatureName>NavigationRouter.swift # Navigation router
```

## Instructions

1. **Ask for the feature name** if not provided as argument
2. **Ask for the main entity type** the feature works with (e.g., `Article`, `User`, `Comment`)
3. **Ask what actions the feature needs** (e.g., load, refresh, select, create, delete)
4. **Create all files** following the exact patterns from Home/Search features

## Template Patterns

### Service Protocol
```swift
import Combine

protocol <FeatureName>Service {
    func fetch<Entity>s(page: Int) -> AnyPublisher<[<Entity>], Error>
}
```

### DomainState
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
            selected<Entity>: nil
        )
    }
}
```

### DomainAction
```swift
enum <FeatureName>DomainAction: Equatable {
    case loadInitialData
    case loadMore
    case refresh
    case select<Entity>(id: String)
    case clearSelected<Entity>
}
```

### ViewEvent
```swift
enum <FeatureName>ViewEvent: Equatable {
    case onAppear
    case onRefresh
    case onLoadMore
    case on<Entity>Tapped(id: String)
    case on<Entity>Navigated
}
```

### ViewState
```swift
struct <FeatureName>ViewState: Equatable {
    var items: [<Entity>ViewItem]
    var isLoading: Bool
    var isLoadingMore: Bool
    var isRefreshing: Bool
    var errorMessage: String?
    var showEmptyState: Bool
    var selected<Entity>: <Entity>?

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
```

### EventActionMap
```swift
struct <FeatureName>EventActionMap: DomainEventActionMap {
    func map(event: <FeatureName>ViewEvent) -> <FeatureName>DomainAction? {
        switch event {
        case .onAppear:
            return .loadInitialData
        case .onRefresh:
            return .refresh
        case .onLoadMore:
            return .loadMore
        case let .on<Entity>Tapped(id):
            return .select<Entity>(id: id)
        case .on<Entity>Navigated:
            return .clearSelected<Entity>
        }
    }
}
```

### ViewStateReducer
```swift
struct <FeatureName>ViewStateReducer: ViewStateReducing {
    func reduce(domainState: <FeatureName>DomainState) -> <FeatureName>ViewState {
        <FeatureName>ViewState(
            items: domainState.items.map { <Entity>ViewItem(from: $0) },
            isLoading: domainState.isLoading,
            isLoadingMore: domainState.isLoadingMore,
            isRefreshing: domainState.isRefreshing,
            errorMessage: domainState.error,
            showEmptyState: !domainState.isLoading && !domainState.isRefreshing && domainState.items.isEmpty,
            selected<Entity>: domainState.selected<Entity>
        )
    }
}
```

### DomainInteractor
```swift
import Combine

final class <FeatureName>DomainInteractor: CombineInteractor {
    typealias DomainState = <FeatureName>DomainState
    typealias DomainAction = <FeatureName>DomainAction

    private let service: <FeatureName>Service
    private let stateSubject = CurrentValueSubject<<FeatureName>DomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<<FeatureName>DomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: <FeatureName>DomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            service = try serviceLocator.retrieve(<FeatureName>Service.self)
        } catch {
            fatalError("Failed to retrieve <FeatureName>Service: \(error)")
        }
    }

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
        }
    }

    private func updateState(_ transform: (inout <FeatureName>DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }

    // MARK: - Private Methods

    private func loadInitialData() {
        guard !currentState.hasLoadedInitialData else { return }
        updateState { $0.isLoading = true }

        service.fetch<Entity>s(page: 1)
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
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func loadMore() {
        guard !currentState.isLoadingMore, currentState.hasMorePages else { return }
        let nextPage = currentState.currentPage + 1
        updateState { $0.isLoadingMore = true }

        service.fetch<Entity>s(page: nextPage)
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
        updateState { $0.isRefreshing = true }

        service.fetch<Entity>s(page: 1)
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

    private func select<Entity>(id: String) {
        guard let item = currentState.items.first(where: { $0.id == id }) else { return }
        updateState { $0.selected<Entity> = item }
    }
}
```

### ViewModel
```swift
import Combine

@MainActor
final class <FeatureName>ViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = <FeatureName>ViewState
    typealias ViewEvent = <FeatureName>ViewEvent

    @Published private(set) var viewState: <FeatureName>ViewState = .initial

    private let serviceLocator: ServiceLocator
    private let interactor: <FeatureName>DomainInteractor
    private let reducer: <FeatureName>ViewStateReducer
    private let eventMap: <FeatureName>EventActionMap
    private var cancellables = Set<AnyCancellable>()

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

    func handle(event: <FeatureName>ViewEvent) {
        guard let action = eventMap.map(event: event) else { return }
        interactor.dispatch(action: action)
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { [reducer] state in reducer.reduce(domainState: state) }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}
```

### NavigationRouter
```swift
import EntropyCore
import UIKit

enum <FeatureName>NavigationEvent {
    case <entity>Detail(<Entity>)
    case settings
}

@MainActor
final class <FeatureName>NavigationRouter: NavigationRouter, Equatable {
    nonisolated(unsafe) var navigation: UINavigationController?
    private nonisolated(unsafe) weak var coordinator: Coordinator?

    init(coordinator: Coordinator? = nil) {
        self.coordinator = coordinator
    }

    func route(navigationEvent: <FeatureName>NavigationEvent) {
        guard let coordinator else { return }

        switch navigationEvent {
        case let .<entity>Detail(item):
            coordinator.push(page: .<entity>Detail(item))
        case .settings:
            coordinator.push(page: .settings)
        }
    }

    nonisolated static func == (lhs: <FeatureName>NavigationRouter, rhs: <FeatureName>NavigationRouter) -> Bool {
        lhs.coordinator === rhs.coordinator
    }
}
```

### View
```swift
import SwiftUI

struct <FeatureName>View<R: <FeatureName>NavigationRouter>: View {
    private var router: R
    @ObservedObject var viewModel: <FeatureName>ViewModel

    init(router: R, viewModel: <FeatureName>ViewModel) {
        self.router = router
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            ColorSystem.backgroundPrimary
                .ignoresSafeArea()
            content
        }
        .navigationTitle("<FeatureName>")
        .refreshable {
            HapticManager.shared.refresh()
            viewModel.handle(event: .onRefresh)
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
        .onChange(of: viewModel.viewState.selected<Entity>) { _, newValue in
            if let item = newValue {
                router.route(navigationEvent: .<entity>Detail(item))
                viewModel.handle(event: .on<Entity>Navigated)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.viewState.isLoading {
            ProgressView()
        } else if viewModel.viewState.showEmptyState {
            emptyState
        } else if let error = viewModel.viewState.errorMessage {
            errorView(error)
        } else {
            listContent
        }
    }

    @ViewBuilder
    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.viewState.items) { item in
                    <Entity>Card(item: item)
                        .onTapGesture {
                            HapticManager.shared.tap()
                            viewModel.handle(event: .on<Entity>Tapped(id: item.id))
                        }
                }

                if viewModel.viewState.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No items yet")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
```

### Live Service
```swift
import Combine

final class Live<FeatureName>Service: APIRequest, <FeatureName>Service {
    func fetch<Entity>s(page: Int) -> AnyPublisher<[<Entity>], Error> {
        // TODO: Implement API call
        fetchRequest(
            target: /* API target */,
            dataType: /* Response type */
        )
        .map { response in
            // Transform response to [<Entity>]
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
```

## Post-Creation Steps

1. **Register Service** in `PulseSceneDelegate.swift`:
   ```swift
   serviceLocator.register(<FeatureName>Service.self, instance: Live<FeatureName>Service())
   ```

2. **Add Navigation Path** to `Coordinator.swift`:
   ```swift
   @Published var <featureName>Path = NavigationPath()
   lazy var <featureName>ViewModel: <FeatureName>ViewModel = .init(serviceLocator: serviceLocator)
   ```

3. **Add Tab** to `CoordinatorView.swift` if needed

4. **Add Page Case** to `Page.swift` if needed

5. **Create Mock Service** in `Configs/Mocks/Mock<FeatureName>Service.swift`
