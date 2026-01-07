import Foundation

/// Domain state for the Digest feature
struct DigestDomainState: Equatable {
    var selectedSource: DigestSource?
    var sourceArticles: [Article]
    var generatedDigest: DigestResult?
    var modelStatus: LLMModelStatus
    var isLoadingArticles: Bool
    var isGenerating: Bool
    var generationProgress: String
    var error: DigestError?
    var userPreferences: UserPreferences

    static var initial: DigestDomainState {
        DigestDomainState(
            selectedSource: nil,
            sourceArticles: [],
            generatedDigest: nil,
            modelStatus: .notLoaded,
            isLoadingArticles: false,
            isGenerating: false,
            generationProgress: "",
            error: nil,
            userPreferences: .default
        )
    }
}

/// Errors that can occur in the Digest feature
enum DigestError: Error, Equatable, LocalizedError {
    case noArticlesAvailable
    case modelNotReady
    case generationFailed(String)
    case loadingFailed(String)
    case noTopicsConfigured

    var errorDescription: String? {
        switch self {
        case .noArticlesAvailable:
            return String(localized: "digest.error.no_articles")
        case .modelNotReady:
            return String(localized: "digest.error.model_not_ready")
        case let .generationFailed(reason):
            return String(localized: "digest.error.generation_failed \(reason)")
        case let .loadingFailed(reason):
            return String(localized: "digest.error.loading_failed \(reason)")
        case .noTopicsConfigured:
            return String(localized: "digest.error.no_topics")
        }
    }
}
