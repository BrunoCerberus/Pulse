import Combine
import Foundation

@MainActor
final class DigestViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = DigestViewState
    typealias ViewEvent = DigestViewEvent

    @Published private(set) var viewState: DigestViewState = .initial

    private let interactor: DigestDomainInteractor
    private var cancellables = Set<AnyCancellable>()

    init(serviceLocator: ServiceLocator) {
        interactor = DigestDomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
    }

    func handle(event: DigestViewEvent) {
        switch event {
        case .onAppear:
            interactor.dispatch(action: .loadSummaries)
        case let .onDeleteSummary(articleID):
            interactor.dispatch(action: .deleteSummary(articleID: articleID))
        case .onRetryTapped:
            interactor.dispatch(action: .loadSummaries)
        case .onClearError:
            interactor.dispatch(action: .clearError)
        }
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                DigestViewState(
                    summaries: state.summaries,
                    isLoading: state.isLoading,
                    isEmpty: state.summaries.isEmpty && !state.isLoading,
                    errorMessage: state.error?.localizedDescription
                )
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}

// MARK: - ViewState

struct DigestViewState: Equatable {
    var summaries: [SummaryItem]
    var isLoading: Bool
    var isEmpty: Bool
    var errorMessage: String?

    static var initial: DigestViewState {
        DigestViewState(
            summaries: [],
            isLoading: false,
            isEmpty: true,
            errorMessage: nil
        )
    }
}

// MARK: - ViewEvent

enum DigestViewEvent: Equatable {
    case onAppear
    case onDeleteSummary(articleID: String)
    case onRetryTapped
    case onClearError
}
