import Combine
import Foundation

@MainActor
final class DigestViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = DigestViewState
    typealias ViewEvent = DigestViewEvent

    @Published private(set) var viewState: DigestViewState = .initial

    private let serviceLocator: ServiceLocator
    private let interactor: DigestDomainInteractor
    private var cancellables = Set<AnyCancellable>()

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        interactor = DigestDomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
    }

    func handle(event: DigestViewEvent) {
        switch event {
        case .onAppear:
            interactor.dispatch(action: .loadModelIfNeeded)
        case .onDisappear:
            // Keep model loaded for quick re-access
            break
        case let .onSourceSelected(source):
            interactor.dispatch(action: .selectSource(source))
        case .onGenerateTapped:
            interactor.dispatch(action: .generateDigest)
        case .onCancelTapped:
            interactor.dispatch(action: .cancelGeneration)
        case .onClearTapped:
            interactor.dispatch(action: .clearDigest)
        case .onRetryTapped:
            interactor.dispatch(action: .retryGeneration)
        case .onSettingsTapped:
            // Handled by router
            break
        }
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { [weak self] state in
                DigestViewState(
                    sources: DigestSource.allCases,
                    selectedSource: state.selectedSource,
                    articleCount: state.sourceArticles.count,
                    articlePreviews: Array(state.sourceArticles.prefix(3)),
                    modelStatus: self?.mapModelStatus(state.modelStatus) ?? .notLoaded,
                    isLoadingArticles: state.isLoadingArticles,
                    isGenerating: state.isGenerating,
                    generationProgress: state.generationProgress,
                    digest: state.generatedDigest,
                    errorMessage: state.error?.localizedDescription,
                    showOnboarding: state.selectedSource == nil,
                    showEmptyState: state.selectedSource != nil
                        && !state.isLoadingArticles
                        && state.sourceArticles.isEmpty
                        && state.error == nil,
                    showNoTopicsError: state.error == .noTopicsConfigured,
                    canGenerate: !state.sourceArticles.isEmpty
                        && state.modelStatus == .ready
                        && !state.isGenerating
                )
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }

    private func mapModelStatus(_ status: LLMModelStatus) -> DigestModelStatus {
        switch status {
        case .notLoaded: return .notLoaded
        case let .loading(progress): return .loading(progress: progress)
        case .ready: return .ready
        case let .error(message): return .error(message)
        }
    }
}

// MARK: - ViewState

struct DigestViewState: Equatable {
    var sources: [DigestSource]
    var selectedSource: DigestSource?
    var articleCount: Int
    var articlePreviews: [Article]
    var modelStatus: DigestModelStatus
    var isLoadingArticles: Bool
    var isGenerating: Bool
    var generationProgress: String
    var digest: DigestResult?
    var errorMessage: String?
    var showOnboarding: Bool
    var showEmptyState: Bool
    var showNoTopicsError: Bool
    var canGenerate: Bool

    static var initial: DigestViewState {
        DigestViewState(
            sources: DigestSource.allCases,
            selectedSource: nil,
            articleCount: 0,
            articlePreviews: [],
            modelStatus: .notLoaded,
            isLoadingArticles: false,
            isGenerating: false,
            generationProgress: "",
            digest: nil,
            errorMessage: nil,
            showOnboarding: true,
            showEmptyState: false,
            showNoTopicsError: false,
            canGenerate: false
        )
    }
}

enum DigestModelStatus: Equatable {
    case notLoaded
    case loading(progress: Double)
    case ready
    case error(String)
}

// MARK: - ViewEvent

enum DigestViewEvent: Equatable {
    case onAppear
    case onDisappear
    case onSourceSelected(DigestSource)
    case onGenerateTapped
    case onCancelTapped
    case onClearTapped
    case onRetryTapped
    case onSettingsTapped
}
