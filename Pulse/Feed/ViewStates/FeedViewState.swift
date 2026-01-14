import Foundation

// MARK: - Processing Phase

enum AIProcessingPhase: Equatable {
    case generating

    var progress: Double {
        1.0
    }

    var isGenerating: Bool {
        true
    }
}

// MARK: - Display State

enum FeedDisplayState: Equatable {
    case idle
    case loading
    case processing(phase: AIProcessingPhase)
    case completed
    case empty
    case error
}

// MARK: - View State

struct FeedViewState: Equatable {
    var displayState: FeedDisplayState
    var headerDate: String
    var streamingText: String
    var digest: DigestViewItem?
    var sourceArticles: [FeedSourceArticle]
    var errorMessage: String?
    var selectedArticle: Article?

    static var initial: FeedViewState {
        FeedViewState(
            displayState: .loading,
            headerDate: "",
            streamingText: "",
            digest: nil,
            sourceArticles: [],
            errorMessage: nil,
            selectedArticle: nil
        )
    }
}

// MARK: - View Items

struct DigestViewItem: Equatable, Identifiable {
    let id: String
    let summary: String
    let articleCount: Int
    let generatedAt: String

    init(from digest: DailyDigest) {
        id = digest.id
        summary = digest.summary
        articleCount = digest.articleCount
        generatedAt = digest.formattedDate
    }
}

struct FeedSourceArticle: Identifiable, Equatable {
    let id: String
    let title: String
    let source: String
    let category: String?
    let imageURL: String?
    let article: Article

    init(from article: Article) {
        id = article.id
        title = article.title
        source = article.source.name
        category = article.category?.displayName
        imageURL = article.imageURL
        self.article = article
    }
}
