import Foundation

/// Represents a summarized article item for display
struct SummaryItem: Equatable, Identifiable {
    let id: String
    let article: Article
    let summary: String
    let generatedAt: Date

    init(article: Article, summary: String, generatedAt: Date) {
        id = article.id
        self.article = article
        self.summary = summary
        self.generatedAt = generatedAt
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: generatedAt, relativeTo: Date())
    }
}

/// Domain state for the Digest feature
struct DigestDomainState: Equatable {
    var summaries: [SummaryItem]
    var isLoading: Bool
    var error: DigestError?

    static var initial: DigestDomainState {
        DigestDomainState(
            summaries: [],
            isLoading: false,
            error: nil
        )
    }
}

/// Errors that can occur in the Digest feature
enum DigestError: Error, Equatable, LocalizedError {
    case loadingFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case let .loadingFailed(reason):
            return String(localized: "digest.error.loading_failed \(reason)")
        case let .deleteFailed(reason):
            return reason
        }
    }
}
