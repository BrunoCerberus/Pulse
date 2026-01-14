import Foundation

// MARK: - Feed Generation State

enum FeedGenerationState: Equatable {
    case idle
    case loadingHistory
    case generating
    case completed
    case error(String)
}

// MARK: - Domain State

struct FeedDomainState: Equatable {
    var generationState: FeedGenerationState
    var readingHistory: [Article]
    var currentDigest: DailyDigest?
    var streamingText: String
    var modelStatus: LLMModelStatus
    var hasLoadedInitialData: Bool
    var selectedArticle: Article?

    static var initial: FeedDomainState {
        FeedDomainState(
            generationState: .idle,
            readingHistory: [],
            currentDigest: nil,
            streamingText: "",
            modelStatus: .notLoaded,
            hasLoadedInitialData: false,
            selectedArticle: nil
        )
    }

    var hasRecentReadingHistory: Bool {
        !readingHistory.isEmpty
    }

    var digestDate: String {
        currentDigest?.formattedDate ?? Self.todayFormatter.string(from: Date())
    }

    private static let todayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
}
