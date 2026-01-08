import Combine
import Foundation

final class DigestDomainInteractor: CombineInteractor {
    typealias DomainState = DigestDomainState
    typealias DomainAction = DigestDomainAction

    private let storageService: StorageService
    private let stateSubject = CurrentValueSubject<DigestDomainState, Never>(.initial)

    var statePublisher: AnyPublisher<DigestDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: DigestDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }
    }

    func dispatch(action: DigestDomainAction) {
        switch action {
        case .loadSummaries:
            loadSummaries()
        case let .deleteSummary(articleID):
            deleteSummary(articleID: articleID)
        case .clearError:
            updateState { $0.error = nil }
        }
    }

    // MARK: - Action Handlers

    private func loadSummaries() {
        updateState { $0.isLoading = true }

        Task { [weak self] in
            guard let self else { return }

            do {
                let summaries = try await storageService.fetchAllSummaries()
                let items = summaries.map { tuple in
                    SummaryItem(
                        article: tuple.article,
                        summary: tuple.summary,
                        generatedAt: tuple.generatedAt
                    )
                }

                await MainActor.run {
                    self.updateState { state in
                        state.summaries = items
                        state.isLoading = false
                        state.error = nil
                    }
                }
            } catch {
                await MainActor.run {
                    self.updateState { state in
                        state.isLoading = false
                        state.error = .loadingFailed(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func deleteSummary(articleID: String) {
        Task { [weak self] in
            guard let self else { return }

            do {
                try await storageService.deleteSummary(articleID: articleID)

                await MainActor.run {
                    self.updateState { state in
                        state.summaries.removeAll { $0.id == articleID }
                    }
                }
            } catch {
                await MainActor.run {
                    self.updateState { state in
                        state.error = .deleteFailed(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func updateState(_ transform: (inout DigestDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
