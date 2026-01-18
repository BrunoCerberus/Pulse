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

    /// Creates one section per category based on source articles
    /// Only categories with articles are shown - no duplicates
    func parseSections(with sourceArticles: [FeedSourceArticle]) -> [DigestSection] {
        // Group articles by category
        var articlesByCategory: [NewsCategory: [FeedSourceArticle]] = [:]

        for article in sourceArticles {
            if let category = article.categoryType {
                articlesByCategory[category, default: []].append(article)
            }
        }

        // No categories with articles - return empty
        guard !articlesByCategory.isEmpty else {
            return []
        }

        // Parse summary paragraphs to match with categories
        let paragraphs = summary.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Skip the first paragraph (key insight) for content matching
        let contentParagraphs = paragraphs.count > 1 ? Array(paragraphs.dropFirst()) : []

        // Define category order for consistent display
        let categoryOrder: [NewsCategory] = [
            .technology, .business, .world, .science, .health, .sports, .entertainment,
        ]

        // Create one section per category that has articles
        var sections: [DigestSection] = []

        for category in categoryOrder {
            guard let articles = articlesByCategory[category], !articles.isEmpty else {
                continue
            }

            // Find a matching paragraph for this category, or generate from article titles
            let content = findContentForCategory(category, from: contentParagraphs, articles: articles)

            sections.append(DigestSection(
                id: "\(id)-section-\(category.rawValue)",
                title: category.displayName,
                content: content,
                category: category,
                relatedArticles: Array(articles.prefix(3)),
                isHighlight: false
            ))
        }

        return sections
    }

    /// Finds relevant content for a category from summary paragraphs or generates from articles
    private func findContentForCategory(
        _ category: NewsCategory,
        from paragraphs: [String],
        articles: [FeedSourceArticle]
    ) -> String {
        // Try to find a paragraph that mentions this category
        for paragraph in paragraphs {
            if detectCategory(from: paragraph) == category {
                return paragraph
            }
        }

        // Generate a description based on article titles
        return generateContentFromArticles(articles, category: category)
    }

    /// Generates a brief content description from article titles
    private func generateContentFromArticles(_ articles: [FeedSourceArticle], category: NewsCategory) -> String {
        guard !articles.isEmpty else {
            return "Coverage of \(category.displayName.lowercased()) topics from your reading."
        }

        // Take up to 2 article titles to create a summary
        let titles = articles.prefix(2).map { $0.title }

        if titles.count == 1 {
            return "Featuring: \(titles[0])"
        } else {
            return "Featuring: \(titles[0]) and more."
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
}
