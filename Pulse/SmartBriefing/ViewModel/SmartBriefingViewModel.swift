import Combine
import EntropyCore
import Foundation

/// ViewModel for the Smart Briefing card embedded in `HomeView`.
///
/// Mirrors `ForYouViewModel`'s small-mini-feature shape (no separate
/// Reducer/EventActionMap files) — this is a card, not a full screen.
@MainActor
final class SmartBriefingViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = SmartBriefingViewState
    typealias ViewEvent = SmartBriefingViewEvent

    @Published private(set) var viewState: SmartBriefingViewState = .initial

    private let interactor: SmartBriefingDomainInteractor

    init(serviceLocator: ServiceLocator) {
        interactor = SmartBriefingDomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
    }

    func handle(event: SmartBriefingViewEvent) {
        switch event {
        case .onAppear:
            interactor.dispatch(action: .loadLastServedMetadata)
        case .onBuildBriefingTapped:
            interactor.dispatch(action: .startBriefing(scope: .unreadSinceLastBriefing))
        case .onStartFreshTapped:
            interactor.dispatch(action: .startBriefing(scope: .allUnread))
        }
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                SmartBriefingViewState(
                    isVisible: state.isPremium,
                    isBuilding: state.buildState == .building,
                    lastServedAt: state.lastServedAt,
                    statusMessage: Self.statusMessage(for: state.buildState)
                )
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }

    private static func statusMessage(for buildState: SmartBriefingBuildState) -> String? {
        switch buildState {
        case .idle, .building:
            nil
        case let .ready(count):
            String(format: AppLocalization.localized("smart_briefing.ready_message"), count)
        case .empty:
            AppLocalization.localized("smart_briefing.empty_message")
        case let .error(message):
            message
        }
    }
}

// MARK: - View State

struct SmartBriefingViewState: Equatable {
    /// `true` only for Premium users — the card is hidden entirely
    /// otherwise, since the Feed tab is the canonical upsell surface.
    var isVisible: Bool
    var isBuilding: Bool
    var lastServedAt: Date?
    /// Transient feedback from the most recent run (e.g. "Queued 12 articles"),
    /// shown briefly after a build completes.
    var statusMessage: String?

    static let initial = SmartBriefingViewState(
        isVisible: false,
        isBuilding: false,
        lastServedAt: nil,
        statusMessage: nil
    )
}

// MARK: - View Event

enum SmartBriefingViewEvent: Equatable {
    case onAppear
    case onBuildBriefingTapped
    case onStartFreshTapped
}
