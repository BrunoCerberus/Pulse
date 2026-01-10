import Combine
import Foundation

final class SummarizationDomainInteractor: CombineInteractor {
    typealias DomainState = SummarizationDomainState
    typealias DomainAction = SummarizationDomainAction

    private let summarizationService: SummarizationService
    private let stateSubject: CurrentValueSubject<SummarizationDomainState, Never>
    private var cancellables = Set<AnyCancellable>()
    private var summarizationTask: Task<Void, Never>?

    var statePublisher: AnyPublisher<SummarizationDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: SummarizationDomainState {
        stateSubject.value
    }

    init(article: Article, serviceLocator: ServiceLocator) {
        stateSubject = CurrentValueSubject(.initial(article: article))

        do {
            summarizationService = try serviceLocator.retrieve(SummarizationService.self)
        } catch {
            Logger.shared.service("Failed to retrieve SummarizationService: \(error)", level: .warning)
            summarizationService = LiveSummarizationService()
        }

        setupBindings()
    }

    private func setupBindings() {
        summarizationService.modelStatusPublisher
            .sink { [weak self] status in
                self?.dispatch(action: .modelStatusChanged(status))
            }
            .store(in: &cancellables)
    }

    func dispatch(action: SummarizationDomainAction) {
        switch action {
        case .startSummarization:
            startSummarization()
        case .cancelSummarization:
            cancelSummarization()
        case let .summarizationStateChanged(newState):
            updateState { $0.summarizationState = newState }
        case let .summarizationTokenReceived(token):
            updateState { $0.generatedSummary += token }
        case let .modelStatusChanged(status):
            handleModelStatusChanged(status)
        }
    }

    // MARK: - Summarization

    private func startSummarization() {
        summarizationTask?.cancel()
        updateState { state in
            state.generatedSummary = ""
            state.summarizationState = .loadingModel(progress: 0)
        }

        summarizationTask = Task { [weak self] in
            guard let self else { return }

            do {
                // loadModelIfNeeded is idempotent and handles concurrent calls
                try await summarizationService.loadModelIfNeeded()

                guard !Task.isCancelled else { return }

                await MainActor.run { [weak self] in
                    self?.dispatch(action: .summarizationStateChanged(.generating))
                }

                var fullText = ""
                var tokensSinceLastUpdate = 0
                let updateBatchSize = 3

                for try await token in summarizationService.summarize(article: currentState.article) {
                    guard !Task.isCancelled else { break }

                    fullText += token
                    tokensSinceLastUpdate += 1

                    if tokensSinceLastUpdate >= updateBatchSize {
                        let currentText = cleanLLMOutput(fullText)
                        await MainActor.run { [weak self] in
                            self?.updateState { $0.generatedSummary = currentText }
                        }
                        tokensSinceLastUpdate = 0
                    }
                }

                guard !Task.isCancelled else { return }

                let finalSummary = cleanLLMOutput(fullText)
                await MainActor.run { [weak self] in
                    self?.updateState { state in
                        state.generatedSummary = finalSummary
                        state.summarizationState = finalSummary.isEmpty ? .error("No summary generated") : .completed
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.dispatch(action: .summarizationStateChanged(.error(error.localizedDescription)))
                }
            }
        }
    }

    private func cancelSummarization() {
        summarizationTask?.cancel()
        summarizationService.cancelSummarization()
        updateState { state in
            state.summarizationState = .idle
            state.generatedSummary = ""
        }
    }

    private func handleModelStatusChanged(_ status: LLMModelStatus) {
        updateState { state in
            state.modelStatus = status
            if case let .loading(progress) = status,
               case .loadingModel = state.summarizationState
            {
                state.summarizationState = .loadingModel(progress: progress)
            } else if case let .error(message) = status {
                state.summarizationState = .error(message)
            }
        }
    }

    private nonisolated func cleanLLMOutput(_ text: String) -> String {
        var cleaned = text

        // Remove chat template markers
        let markers = [
            "<|system|>", "<|user|>", "<|assistant|>", "<|end|>",
            "</s>", "<s>", "<|eot_id|>", "<|start_header_id|>", "<|end_header_id|>",
        ]
        for marker in markers {
            cleaned = cleaned.replacingOccurrences(of: marker, with: "")
        }

        // Remove common instruction artifacts (case-insensitive, at start)
        let prefixes = ["here's the summary:", "here is the summary:", "summary:"]
        let lowercased = cleaned.lowercased()
        for prefix in prefixes where lowercased.hasPrefix(prefix) {
            cleaned = String(cleaned.dropFirst(prefix.count))
            break
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func updateState(_ transform: (inout SummarizationDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }

    deinit {
        summarizationTask?.cancel()
    }
}
