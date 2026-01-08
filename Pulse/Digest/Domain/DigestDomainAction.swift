import Foundation

/// Domain actions for the Digest feature
enum DigestDomainAction: Equatable {
    /// Load all saved summaries from storage
    case loadSummaries

    /// Delete a specific summary by article ID
    case deleteSummary(articleID: String)

    /// Clear any displayed error
    case clearError
}
