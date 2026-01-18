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
    let categoryType: NewsCategory?
    let imageURL: String?
    let article: Article

    init(from article: Article) {
        id = article.id
        title = article.title
        source = article.source.name
        category = article.category?.displayName
        categoryType = article.category
        imageURL = article.imageURL
        self.article = article
    }
}

// MARK: - Digest Section

struct DigestSection: Identifiable, Equatable {
    let id: String
    let title: String
    let content: String
    let category: NewsCategory?
    let relatedArticles: [FeedSourceArticle]
    let isHighlight: Bool

    init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        category: NewsCategory? = nil,
        relatedArticles: [FeedSourceArticle] = [],
        isHighlight: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.relatedArticles = relatedArticles
        self.isHighlight = isHighlight
    }
}

// MARK: - DigestViewItem Extensions

extension DigestViewItem {
    /// Extracts the first paragraph as the key insight
    var keyInsight: String {
        let paragraphs = summary.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return paragraphs.first ?? summary
    }

    /// Parses the summary into sections based on paragraph structure
    func parseSections(with sourceArticles: [FeedSourceArticle]) -> [DigestSection] {
        let paragraphs = summary.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard paragraphs.count > 1 else {
            // Single paragraph - return as key insight only
            return []
        }

        // Skip the first paragraph (key insight) and create sections from the rest
        let remainingParagraphs = Array(paragraphs.dropFirst())

        return remainingParagraphs.enumerated().map { index, paragraph in
            // Try to detect category from paragraph content
            let detectedCategory = detectCategory(from: paragraph)

            // Find related articles for this section
            let relatedArticles = findRelatedArticles(
                for: paragraph,
                category: detectedCategory,
                from: sourceArticles
            )

            // Generate a title based on category or generic
            let title = sectionTitle(for: detectedCategory, index: index)

            return DigestSection(
                id: "\(id)-section-\(index)",
                title: title,
                content: paragraph,
                category: detectedCategory,
                relatedArticles: Array(relatedArticles.prefix(3)),
                isHighlight: false
            )
        }
    }

    /// Computes category breakdown from source articles
    func computeTopicsBreakdown(from sourceArticles: [FeedSourceArticle]) -> [(NewsCategory, Int)] {
        var categoryCount: [NewsCategory: Int] = [:]

        for article in sourceArticles {
            if let category = article.categoryType {
                categoryCount[category, default: 0] += 1
            }
        }

        return categoryCount
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
    }

    // MARK: - Private Helpers

    private func detectCategory(from text: String) -> NewsCategory? {
        let lowercasedText = text.lowercased()

        let categoryKeywords: [NewsCategory: [String]] = [
            .technology: ["technology", "tech", "ai", "artificial intelligence", "software", "app", "digital", "computer", "startup"],
            .business: ["business", "market", "economy", "stock", "trade", "company", "finance", "invest", "economic"],
            .world: ["world", "international", "global", "country", "nation", "foreign", "diplomatic"],
            .science: ["science", "research", "study", "discover", "experiment", "scientist"],
            .health: ["health", "medical", "doctor", "hospital", "disease", "treatment", "wellness"],
            .sports: ["sport", "game", "team", "player", "match", "championship", "athlete"],
            .entertainment: ["entertainment", "movie", "film", "music", "celebrity", "actor", "show"],
        ]

        for (category, keywords) in categoryKeywords {
            for keyword in keywords where lowercasedText.contains(keyword) {
                return category
            }
        }

        return nil
    }

    private func findRelatedArticles(
        for _: String,
        category: NewsCategory?,
        from sourceArticles: [FeedSourceArticle]
    ) -> [FeedSourceArticle] {
        // First, try to match by category
        if let category {
            let categoryMatches = sourceArticles.filter { $0.categoryType == category }
            if !categoryMatches.isEmpty {
                return categoryMatches
            }
        }

        // Fallback: return first few articles
        return Array(sourceArticles.prefix(2))
    }

    private func sectionTitle(for category: NewsCategory?, index: Int) -> String {
        if let category {
            return category.displayName
        }

        // Generic titles for sections without detected category
        let genericTitles = ["Deep Dive", "In Focus", "Highlights", "More Coverage"]
        return genericTitles[index % genericTitles.count]
    }
}
