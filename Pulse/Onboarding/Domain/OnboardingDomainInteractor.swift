import Combine
import EntropyCore
import Foundation

@MainActor
final class OnboardingDomainInteractor: CombineInteractor {
    typealias DomainState = OnboardingDomainState
    typealias DomainAction = OnboardingDomainAction

    private let stateSubject = CurrentValueSubject<DomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    private var onboardingService: OnboardingService
    private let analyticsService: AnalyticsService?
    private let settingsService: SettingsService?
    private var loadedPreferences: UserPreferences?
    private var userHasTouchedTopics = false

    var statePublisher: AnyPublisher<DomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: DomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        onboardingService = (try? serviceLocator.retrieve(OnboardingService.self)) ?? MockOnboardingService()
        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)
        settingsService = try? serviceLocator.retrieve(SettingsService.self)

        loadPreferences()
    }

    func dispatch(action: DomainAction) {
        switch action {
        case .nextPage:
            handleNextPage()
        case let .goToPage(page):
            updateState { $0.currentPage = page }
        case let .toggleTopic(category):
            handleToggleTopic(category)
        case .skip:
            handleSkip()
        case .complete:
            handleComplete()
        }
    }

    private func loadPreferences() {
        guard let settingsService else { return }
        settingsService.fetchPreferences()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] preferences in
                    guard let self else { return }
                    loadedPreferences = preferences
                    // Pre-populate selections from existing prefs (e.g. CloudKit-restored account)
                    // unless the user has already started making choices on this run.
                    if !userHasTouchedTopics, !preferences.followedTopics.isEmpty {
                        updateState { $0.selectedTopics = Set(preferences.followedTopics) }
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func handleNextPage() {
        let pages = OnboardingPage.allCases
        let currentIndex = pages.firstIndex(of: currentState.currentPage) ?? 0

        if currentIndex < pages.count - 1 {
            updateState { $0.currentPage = pages[currentIndex + 1] }
        } else {
            handleComplete()
        }
    }

    private func handleToggleTopic(_ category: NewsCategory) {
        userHasTouchedTopics = true
        updateState { state in
            if state.selectedTopics.contains(category) {
                state.selectedTopics.remove(category)
            } else {
                state.selectedTopics.insert(category)
            }
        }
    }

    private func handleSkip() {
        analyticsService?.logEvent(.onboardingSkipped(page: currentState.currentPage.rawValue))
        markCompleted()
    }

    private func handleComplete() {
        let selected = currentState.selectedTopics
        if !selected.isEmpty {
            persistSelectedTopics(selected)
            analyticsService?.logEvent(
                .onboardingTopicsSelected(
                    count: selected.count,
                    topics: selected.map(\.rawValue).sorted()
                )
            )
        }
        analyticsService?.logEvent(.onboardingCompleted(page: currentState.currentPage.rawValue))
        markCompleted()
    }

    private func persistSelectedTopics(_ topics: Set<NewsCategory>) {
        guard let settingsService else { return }
        // Preserve input-order stability by sorting by declaration order.
        let orderedTopics = NewsCategory.allCases.filter { topics.contains($0) }
        // Re-fetch preferences before saving so we merge against the freshest
        // stored value. Without this, if "Get Started" fires before the initial
        // fetchPreferences() resolves (e.g. slow CloudKit cold read), we'd fall
        // back to UserPreferences.default and wipe mutedSources, mutedKeywords,
        // preferredLanguage, notificationsEnabled, and breakingNewsNotifications.
        let fallback: UserPreferences = loadedPreferences ?? .default
        settingsService.fetchPreferences()
            .catch { _ in Just(fallback).setFailureType(to: Error.self) }
            .flatMap { preferences -> AnyPublisher<Void, Error> in
                var updated = preferences
                updated.followedTopics = orderedTopics
                return settingsService.savePreferences(updated)
            }
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.analyticsService?.recordError(error)
                        Logger.shared.service(
                            "Failed to persist onboarding topic selection: \(error)",
                            level: .warning
                        )
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func markCompleted() {
        onboardingService.hasCompletedOnboarding = true
        updateState { $0.isCompleted = true }
    }

    private func updateState(_ transform: (inout DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
