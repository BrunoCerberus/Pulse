import Combine
import EntropyCore
import Foundation

/// Domain interactor for Smart Briefing — an on-demand, personalized audio
/// playlist of unread articles, distinct from the scheduled Morning
/// Briefing (which narrates an LLM-generated digest). No digest text is
/// generated here: candidate articles are ranked by `ForYouService` and
/// handed straight to the global `PlaybackQueueService`.
///
/// - Note: This is a **Premium** feature (`PremiumFeature.audioBriefing`).
@MainActor
final class SmartBriefingDomainInteractor: CombineInteractor {
    typealias DomainState = SmartBriefingDomainState
    typealias DomainAction = SmartBriefingDomainAction

    let newsService: NewsService
    let forYouService: ForYouService?
    let storageService: StorageService?
    let playbackQueueService: PlaybackQueueService?
    let smartBriefingCacheService: SmartBriefingCacheService?
    let settingsService: SettingsService?
    let storeKitService: StoreKitService?
    let analyticsService: AnalyticsService?

    private let stateSubject = CurrentValueSubject<DomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()
    var buildTask: Task<Void, Never>?

    var statePublisher: AnyPublisher<DomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: DomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            newsService = try serviceLocator.retrieve(NewsService.self)
        } catch {
            fatalError("SmartBriefingDomainInteractor requires NewsService: \(error)")
        }

        forYouService = try? serviceLocator.retrieve(ForYouService.self)
        storageService = try? serviceLocator.retrieve(StorageService.self)
        playbackQueueService = try? serviceLocator.retrieve(PlaybackQueueService.self)
        smartBriefingCacheService = try? serviceLocator.retrieve(SmartBriefingCacheService.self)
        settingsService = try? serviceLocator.retrieve(SettingsService.self)
        storeKitService = try? serviceLocator.retrieve(StoreKitService.self)
        analyticsService = try? serviceLocator.retrieve(AnalyticsService.self)

        stateSubject.value.isPremium = storeKitService?.isPremium ?? false
        storeKitService?.subscriptionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPremium in
                self?.updateState { $0.isPremium = isPremium }
            }
            .store(in: &cancellables)
    }

    func dispatch(action: DomainAction) {
        switch action {
        case .loadLastServedMetadata:
            updateState { $0.lastServedAt = smartBriefingCacheService?.fetchLastServed()?.servedAt }
        case let .startBriefing(scope):
            startBriefing(scope: scope)
        case let .buildSucceeded(itemCount, servedAt):
            updateState { state in
                state.buildState = itemCount > 0 ? .ready(count: itemCount) : .empty
                state.lastServedAt = servedAt
            }
        case let .buildFailed(message):
            updateState { $0.buildState = .error(message) }
        }
    }

    func updateState(_ transform: (inout DomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }

    deinit {
        buildTask?.cancel()
    }
}
