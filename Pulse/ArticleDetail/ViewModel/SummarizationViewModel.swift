import Combine
import Foundation

enum SummarizationState: Equatable {
    case idle
    case loadingModel(progress: Double)
    case generating
    case completed
    case error(String)
}

@MainActor
final class SummarizationViewModel: ObservableObject {
    @Published private(set) var state: SummarizationState = .idle
    @Published private(set) var generatedSummary: String = ""
    @Published private(set) var modelStatus: LLMModelStatus = .notLoaded

    private let summarizationService: SummarizationService
    private let storageService: StorageService
    private var generationTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(serviceLocator: ServiceLocator) {
        do {
            summarizationService = try serviceLocator.retrieve(SummarizationService.self)
        } catch {
            Logger.shared.service("Failed to retrieve SummarizationService: \(error)", level: .warning)
            summarizationService = LiveSummarizationService()
        }

        do {
            storageService = try serviceLocator.retrieve(StorageService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StorageService: \(error)", level: .warning)
            storageService = LiveStorageService()
        }

        setupBindings()
    }

    private func setupBindings() {
        summarizationService.modelStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.modelStatus = status
                self?.updateStateFromModelStatus(status)
            }
            .store(in: &cancellables)
    }

    private func updateStateFromModelStatus(_ status: LLMModelStatus) {
        switch status {
        case let .loading(progress):
            if case .loadingModel = state {
                state = .loadingModel(progress: progress)
            }
        case let .error(message):
            state = .error(message)
        default:
            break
        }
    }

    func startSummarization(article: Article) {
        generationTask?.cancel()
        generatedSummary = ""

        generationTask = Task { [weak self] in
            guard let self else { return }

            do {
                if !summarizationService.isModelLoaded {
                    state = .loadingModel(progress: 0)
                    try await summarizationService.loadModelIfNeeded()
                }

                state = .generating

                var tokenBuffer: [String] = []
                let updateBatchSize = 3

                for try await token in summarizationService.summarize(article: article) {
                    if Task.isCancelled { break }

                    tokenBuffer.append(token)

                    if tokenBuffer.count >= updateBatchSize {
                        let currentText = cleanLLMOutput(tokenBuffer.joined())
                        generatedSummary = currentText
                    }
                }

                if !Task.isCancelled {
                    let finalSummary = cleanLLMOutput(tokenBuffer.joined())
                    generatedSummary = finalSummary
                    state = finalSummary.isEmpty ? .error("No summary generated") : .completed
                }
            } catch {
                if !Task.isCancelled {
                    state = .error(error.localizedDescription)
                }
            }
        }
    }

    /// Cleans up LLM output by removing prompt template markers and trimming whitespace
    private func cleanLLMOutput(_ text: String) -> String {
        var cleaned = text
        // Remove common prompt template markers
        let markers = ["<|system|>", "<|user|>", "<|assistant|>", "<|end|>", "</s>", "<s>"]
        for marker in markers {
            cleaned = cleaned.replacingOccurrences(of: marker, with: "")
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func cancel() {
        generationTask?.cancel()
        summarizationService.cancelSummarization()
        state = .idle
        generatedSummary = ""
    }

    func saveSummary(article: Article) async throws {
        let trimmedSummary = generatedSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSummary.isEmpty else { return }
        try await storageService.saveSummary(article, summary: trimmedSummary)
    }

    func reset() {
        generationTask?.cancel()
        state = .idle
        generatedSummary = ""
    }
}
