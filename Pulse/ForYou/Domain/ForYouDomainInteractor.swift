import Combine
import EntropyCore
import Foundation

/// Domain interactor for the For You carousel.
///
/// Owns the scored-article state and listens for profile changes so the
/// carousel re-ranks without a host-driven refresh. The host (`HomeView`
/// via its `ForYouViewModel`) is responsible for dispatching `.scoreFromPool`
/// each time its own article pool changes.
@MainActor
final class ForYouDomainInteractor: CombineInteractor {
    typealias DomainState = ForYouDomainState
    typealias DomainAction = ForYouDomainAction

    private let forYouService: ForYouService?
    private let analyticsService: AnalyticsService?
    private let stateSubject = CurrentValueSubject<DomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()
    private var lastPool: [Article] = []
    private var inflightTask: Task<Void, Never>?

    /// How many top-scored articles to surface in the carousel.
    private let topN: Int = 10

    var statePublisher: AnyPublisher<DomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: DomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        forYouService = try? serviceLocator.retrieve(ForYouService.self)
        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)

        observeProfileChanges()
        observeCloudSync()
    }

    func dispatch(action: DomainAction) {
        switch action {
        case let .scoreFromPool(pool):
            lastPool = pool
            runScoring()
        case .rescore:
            runScoring()
        }
    }

    // MARK: - Subscriptions

    private func observeProfileChanges() {
        NotificationCenter.default.publisher(for: .interestProfileDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.runScoring()
            }
            .store(in: &cancellables)
    }

    private func observeCloudSync() {
        NotificationCenter.default.publisher(for: .cloudSyncDidComplete)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.runScoring()
            }
            .store(in: &cancellables)
    }

    // MARK: - Scoring

    private func runScoring() {
        guard let forYouService else { return }
        guard !lastPool.isEmpty else {
            updateState { state in
                state.scoredArticles = []
                state.isLoading = false
            }
            return
        }

        // Cancel any inflight scoring — the latest pool wins.
        inflightTask?.cancel()
        updateState { $0.isLoading = true }

        let pool = lastPool
        let topN = topN
        let service = UncheckedSendableBox(value: forYouService)

        inflightTask = Task { [weak self] in
            do {
                let result = try await service.value.scoredArticles(from: pool, topN: topN)
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.updateState { state in
                        state.scoredArticles = result
                        state.isLoading = false
                        state.error = nil
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.updateState { state in
                        state.scoredArticles = []
                        state.isLoading = false
                        state.error = error.localizedDescription
                    }
                    self?.analyticsService?.recordError(error)
                }
            }
        }
    }

    private func updateState(_ transform: (inout DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
    
    deinit {
        // Cancel all pending tasks on deallocation
        for task in backgroundTasks {
            task.cancel()
        }
    }
}
