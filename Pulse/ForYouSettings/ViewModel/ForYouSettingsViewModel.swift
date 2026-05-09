import Combine
import EntropyCore
import Foundation

/// ViewModel for the For You settings screen.
///
/// Mirrors the simpler `BookmarksViewModel` shape: inline ViewState /
/// ViewEvent and direct event-to-action mapping in `handle(event:)`.
@MainActor
final class ForYouSettingsViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = ForYouSettingsViewState
    typealias ViewEvent = ForYouSettingsViewEvent

    @Published private(set) var viewState: ForYouSettingsViewState = .initial

    private let interactor: ForYouSettingsDomainInteractor

    init(serviceLocator: ServiceLocator) {
        interactor = ForYouSettingsDomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
    }

    func handle(event: ForYouSettingsViewEvent) {
        switch event {
        case .onAppear:
            interactor.dispatch(action: .loadProfile)
        case let .onRemoveTopic(topicID):
            interactor.dispatch(action: .removeTopic(topicID: topicID))
        case .onResetTapped:
            interactor.dispatch(action: .requestReset)
        case .onResetConfirmed:
            interactor.dispatch(action: .confirmReset)
        case .onResetCancelled:
            interactor.dispatch(action: .cancelReset)
        }
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                ForYouSettingsViewState(
                    rows: state.topics.map(ForYouTopicRow.init(from:)),
                    isLoading: state.isLoading,
                    showEmptyState: !state.isLoading && state.topics.isEmpty,
                    showResetConfirmation: state.showResetConfirmation,
                    errorMessage: state.error
                )
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}

// MARK: - View State

struct ForYouSettingsViewState: Equatable {
    var rows: [ForYouTopicRow]
    var isLoading: Bool
    var showEmptyState: Bool
    var showResetConfirmation: Bool
    var errorMessage: String?

    static var initial: ForYouSettingsViewState {
        ForYouSettingsViewState(
            rows: [],
            isLoading: false,
            showEmptyState: false,
            showResetConfirmation: false,
            errorMessage: nil
        )
    }
}

/// View item for a single interest-topic row in the settings list.
struct ForYouTopicRow: Identifiable, Equatable {
    let id: String
    let displayName: String
    /// Pre-formatted weight string (e.g. `"2.4"`) for the trailing label.
    let weightLabel: String
    let sourceLabel: String
    /// Normalised `[0, 1]` weight for any progress-bar visualization.
    let weightFraction: Double

    init(from topic: InterestTopic) {
        id = topic.topicID
        displayName = topic.displayName.isEmpty
            ? TopicExtractionPromptBuilder.displayName(for: topic.topicID)
            : topic.displayName
        weightLabel = String(format: "%.1f", topic.weight)
        sourceLabel = topic.source.rawValue.capitalized
        // Normalise visually: anything ≥10 is "full" — keeps the bar
        // useful without making early seed rows look maxed out.
        weightFraction = max(0, min(1, topic.weight / 10))
    }
}

// MARK: - View Event

enum ForYouSettingsViewEvent: Equatable {
    case onAppear
    case onRemoveTopic(topicID: String)
    case onResetTapped
    case onResetConfirmed
    case onResetCancelled
}
