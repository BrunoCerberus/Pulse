import Combine
import EntropyCore
import Foundation

/// News service implementation using Supabase backend via REST API.
///
/// Fetches articles from the Pulse backend database populated by RSS feeds.
/// Falls back to Guardian API if Supabase is not configured.
final class SupabaseNewsService: APIRequest, NewsService {
    // MARK: - Properties

    private let fallbackService: NewsService?
    private let isConfigured: Bool

    // MARK: - Initialization

    init(fallbackService: NewsService? = nil) {
        self.fallbackService = fallbackService
        isConfigured = SupabaseConfig.isConfigured

        super.init()

        if isConfigured {
            Logger.shared.service("SupabaseNewsService: initialized with Supabase backend", level: .info)
        } else {
            Logger.shared.service("SupabaseNewsService: Supabase not configured, using fallback", level: .warning)
        }
    }

    // MARK: - NewsService

    func fetchTopHeadlines(country: String, page: Int) -> AnyPublisher<[Article], Error> {
        guard isConfigured else {
            return fallbackService?.fetchTopHeadlines(country: country, page: page)
                ?? Fail(error: SupabaseNewsError.notConfigured).eraseToAnyPublisher()
        }

        return fetchRequest(
            target: SupabaseAPI.articles(page: page, pageSize: 20),
            dataType: [SupabaseArticle].self
        )
        .map { response in
            response.map { $0.toArticle() }
        }
        .handleEvents(receiveOutput: { articles in
            Logger.shared.service("SupabaseNewsService: fetchTopHeadlines returned \(articles.count) articles", level: .info)
        }, receiveCompletion: { completion in
            if case let .failure(error) = completion {
                Logger.shared.service("SupabaseNewsService: fetchTopHeadlines failed - \(error.localizedDescription)", level: .error)
            }
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func fetchTopHeadlines(category: NewsCategory, country: String, page: Int) -> AnyPublisher<[Article], Error> {
        guard isConfigured else {
            return fallbackService?.fetchTopHeadlines(category: category, country: country, page: page)
                ?? Fail(error: SupabaseNewsError.notConfigured).eraseToAnyPublisher()
        }

        return fetchRequest(
            target: SupabaseAPI.articlesByCategory(category: category.rawValue, page: page, pageSize: 20),
            dataType: [SupabaseArticle].self
        )
        .map { response in
            response.map { $0.toArticle() }
        }
        .handleEvents(receiveOutput: { articles in
            Logger.shared.service("SupabaseNewsService: fetchTopHeadlines(category: \(category.rawValue)) returned \(articles.count) articles", level: .info)
        }, receiveCompletion: { completion in
            if case let .failure(error) = completion {
                Logger.shared.service("SupabaseNewsService: fetchTopHeadlines(category:) failed - \(error.localizedDescription)", level: .error)
            }
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func fetchBreakingNews(country: String) -> AnyPublisher<[Article], Error> {
        guard isConfigured else {
            return fallbackService?.fetchBreakingNews(country: country)
                ?? Fail(error: SupabaseNewsError.notConfigured).eraseToAnyPublisher()
        }

        let oneDayAgo = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400))

        return fetchRequest(
            target: SupabaseAPI.breakingNews(since: oneDayAgo),
            dataType: [SupabaseArticle].self
        )
        .map { response in
            response.map { $0.toArticle() }
        }
        .handleEvents(receiveOutput: { articles in
            Logger.shared.service("SupabaseNewsService: fetchBreakingNews returned \(articles.count) articles", level: .info)
        }, receiveCompletion: { completion in
            if case let .failure(error) = completion {
                Logger.shared.service("SupabaseNewsService: fetchBreakingNews failed - \(error.localizedDescription)", level: .error)
            }
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func fetchArticle(id: String) -> AnyPublisher<Article, Error> {
        guard isConfigured else {
            return fallbackService?.fetchArticle(id: id)
                ?? Fail(error: SupabaseNewsError.notConfigured).eraseToAnyPublisher()
        }

        return fetchRequest(
            target: SupabaseAPI.article(id: id),
            dataType: [SupabaseArticle].self
        )
        .tryMap { response in
            guard let article = response.first else {
                throw SupabaseNewsError.articleNotFound
            }
            return article.toArticle()
        }
        .handleEvents(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                Logger.shared.service("SupabaseNewsService: fetchArticle failed - \(error.localizedDescription)", level: .error)
            }
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}

// MARK: - Supabase Response Models

/// Article data from Supabase REST API with embedded relations.
/// Note: Uses snake_case property names since EntropyCore's jsonDecoder uses convertFromSnakeCase
struct SupabaseArticle: Codable {
    let id: String
    let title: String
    let summary: String?
    let content: String?
    let url: String
    let imageUrl: String?
    let thumbnailUrl: String?
    let author: String?
    let publishedAt: String // ISO8601 string from Supabase
    let sources: SupabaseSource?
    let categories: SupabaseCategory?

    // No CodingKeys needed - convertFromSnakeCase handles image_url -> imageUrl, etc.

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601FormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    func toArticle() -> Article {
        // Parse ISO8601 date string
        let date: Date
        if let parsed = Self.iso8601Formatter.date(from: publishedAt) {
            date = parsed
        } else if let parsed = Self.iso8601FormatterNoFraction.date(from: publishedAt) {
            date = parsed
        } else {
            Logger.shared.service("SupabaseArticle: Failed to parse date '\(publishedAt)' for article \(id)", level: .warning)
            date = Date()
        }

        // Handle content/description mapping for RSS feeds:
        // - If content exists, use summary as description (short preview) and content as body
        // - If only summary exists, use it as full content (no description to avoid duplication)
        let articleDescription: String?
        let articleContent: String?

        if let fullContent = content, !fullContent.isEmpty {
            // Backend has both fields populated
            articleDescription = summary
            articleContent = fullContent
        } else if let summaryText = summary, !summaryText.isEmpty {
            // RSS feed only has summary - use it as content, no description to avoid duplication
            articleDescription = nil
            articleContent = summaryText
        } else {
            articleDescription = nil
            articleContent = nil
        }

        // Handle image URLs: RSS feeds often only have one image
        // Use whatever is available, preferring full-size image_url for hero images
        // Don't fallback to full-res for thumbnail to avoid loading large images in list views
        let fullImageURL = imageUrl ?? thumbnailUrl
        let thumbURL = thumbnailUrl

        return Article(
            id: id,
            title: title,
            description: articleDescription,
            content: articleContent,
            author: author,
            source: ArticleSource(id: sources?.slug, name: sources?.name ?? "Unknown"),
            url: url,
            imageURL: fullImageURL,
            thumbnailURL: thumbURL,
            publishedAt: date,
            category: categories.flatMap { NewsCategory(rawValue: $0.slug) }
        )
    }
}

/// Source data - only decode fields we need, ignore extra fields
struct SupabaseSource: Codable {
    let id: String
    let name: String
    let slug: String
    let logoUrl: String?
    let websiteUrl: String?
    // Extra fields from API are ignored automatically
}

/// Category data - only decode fields we need
struct SupabaseCategory: Codable {
    let id: String
    let name: String
    let slug: String
    // Extra fields like created_at, display_order are ignored
}

// MARK: - Errors

enum SupabaseNewsError: Error, LocalizedError {
    case notConfigured
    case articleNotFound

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase backend is not configured"
        case .articleNotFound:
            return "Article not found"
        }
    }
}
