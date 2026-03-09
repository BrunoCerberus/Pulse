import Combine
import EntropyCore
import Foundation

/// Manages business logic for Story Threads, coordinating between the service layer and state.
@MainActor
final class StoryThreadDomainInteractor: CombineInteractor {
    typealias DomainState = StoryThreadDomainState
    typealias DomainAction = StoryThreadDomainAction

    let stateSubject = CurrentValueSubject<StoryThreadDomainState, Never>(.initial)
    var cancellables = Set<AnyCancellable>()

    private let storyThreadService: StoryThreadService
    private let analyticsService: AnalyticsService?

    var statePublisher: AnyPublisher<StoryThreadDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: StoryThreadDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        storyThreadService = (try? serviceLocator.retrieve(StoryThreadService.self))
            ?? MockStoryThreadService()
        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)
    }

    func dispatch(action: StoryThreadDomainAction) {
        switch action {
        case .loadFollowedThreads:
            loadFollowedThreads()
        case let .loadThreadsForArticle(articleID):
            loadThreads(for: articleID)
        case let .followThread(id):
            followThread(id: id)
        case let .unfollowThread(id):
            unfollowThread(id: id)
        case let .generateSummary(threadID):
            generateSummary(for: threadID)
        case let .markThreadAsRead(id):
            markAsRead(id: id)
        case .refresh:
            refresh()
        }
    }

    // MARK: - Private

    private func updateState(_ transform: (inout StoryThreadDomainState) -> Void) {
        var state = currentState
        transform(&state)
        stateSubject.send(state)
    }

    private func loadFollowedThreads() {
        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        storyThreadService.fetchFollowedThreads()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.updateState { state in
                            state.isLoading = false
                            state.error = error.localizedDescription
                        }
                        self?.analyticsService?.recordError(error)
                    }
                },
                receiveValue: { [weak self] threads in
                    self?.updateState { state in
                        state.threads = threads
                        state.isLoading = false
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func loadThreads(for articleID: String) {
        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        storyThreadService.fetchThreads(for: articleID)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.updateState { state in
                            state.isLoading = false
                            state.error = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] threads in
                    self?.updateState { state in
                        state.threads = threads
                        state.isLoading = false
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func followThread(id: UUID) {
        storyThreadService.followThread(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.analyticsService?.recordError(error)
                    }
                },
                receiveValue: { [weak self] in
                    self?.updateState { state in
                        if let index = state.threads.firstIndex(where: { $0.id == id }) {
                            state.threads[index].isFollowing = true
                        }
                    }
                    self?.analyticsService?.logEvent(.storyThreadFollowed(threadID: id.uuidString))
                }
            )
            .store(in: &cancellables)
    }

    private func unfollowThread(id: UUID) {
        storyThreadService.unfollowThread(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.analyticsService?.recordError(error)
                    }
                },
                receiveValue: { [weak self] in
                    self?.updateState { state in
                        if let index = state.threads.firstIndex(where: { $0.id == id }) {
                            state.threads[index].isFollowing = false
                        }
                    }
                    self?.analyticsService?.logEvent(.storyThreadUnfollowed(threadID: id.uuidString))
                }
            )
            .store(in: &cancellables)
    }

    private func generateSummary(for threadID: UUID) {
        guard let thread = currentState.threads.first(where: { $0.id == threadID }) else { return }

        updateState { state in
            state.generatingSummaryForID = threadID
        }

        storyThreadService.generateThreadSummary(thread: thread)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.updateState { state in
                        state.generatingSummaryForID = nil
                    }
                    if case let .failure(error) = completion {
                        self?.analyticsService?.recordError(error)
                    }
                },
                receiveValue: { [weak self] summary in
                    self?.updateState { state in
                        if let index = state.threads.firstIndex(where: { $0.id == threadID }) {
                            state.threads[index].summary = summary
                        }
                    }
                    self?.analyticsService?.logEvent(.storyThreadSummaryGenerated(threadID: threadID.uuidString))
                }
            )
            .store(in: &cancellables)
    }

    private func markAsRead(id: UUID) {
        storyThreadService.markThreadAsRead(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] in
                    self?.updateState { state in
                        if let index = state.threads.firstIndex(where: { $0.id == id }) {
                            state.threads[index].lastReadAt = .now
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func refresh() {
        updateState { state in
            state.isRefreshing = true
            state.error = nil
        }

        storyThreadService.fetchFollowedThreads()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.updateState { state in
                        state.isRefreshing = false
                    }
                    if case let .failure(error) = completion {
                        self?.updateState { state in
                            state.error = error.localizedDescription
                        }
                        self?.analyticsService?.recordError(error)
                    }
                },
                receiveValue: { [weak self] threads in
                    self?.updateState { state in
                        state.threads = threads
                    }
                }
            )
            .store(in: &cancellables)
    }
}
