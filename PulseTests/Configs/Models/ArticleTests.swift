import Foundation
@testable import Pulse
import Testing

@Suite("Article Model Tests")
struct ArticleTests {
    // MARK: - Test Data

    private var fixedDate: Date {
        Date(timeIntervalSince1970: 1_672_531_200) // Jan 1, 2023
    }

    private var testSource: ArticleSource {
        ArticleSource(id: "test-source", name: "Test News")
    }

    // MARK: - Initialization Tests

    @Test("Article initializes with all properties")
    func initializesWithAllProperties() {
        let article = Article(
            id: "custom-id",
            title: "Test Article",
            description: "Test description",
            content: "Full content here",
            author: "John Doe",
            source: testSource,
            url: "https://example.com/article",
            imageURL: "https://example.com/image.jpg",
            publishedAt: fixedDate,
            category: .technology
        )

        #expect(article.id == "custom-id")
        #expect(article.title == "Test Article")
        #expect(article.description == "Test description")
        #expect(article.content == "Full content here")
        #expect(article.author == "John Doe")
        #expect(article.source == testSource)
        #expect(article.url == "https://example.com/article")
        #expect(article.imageURL == "https://example.com/image.jpg")
        #expect(article.publishedAt == fixedDate)
        #expect(article.category == .technology)
    }

    @Test("Article initializes with default UUID when id not provided")
    func initializesWithDefaultUUID() {
        let article = Article(
            title: "Test Article",
            source: testSource,
            url: "https://example.com/article",
            publishedAt: fixedDate
        )

        // ID should be a valid UUID string
        #expect(!article.id.isEmpty)
        #expect(UUID(uuidString: article.id) != nil, "Auto-generated ID should be a valid UUID")
    }

    @Test("Article initializes with nil optional properties")
    func initializesWithNilOptionals() {
        let article = Article(
            title: "Test Article",
            source: testSource,
            url: "https://example.com/article",
            publishedAt: fixedDate
        )

        #expect(article.description == nil)
        #expect(article.content == nil)
        #expect(article.author == nil)
        #expect(article.imageURL == nil)
        #expect(article.category == nil)
    }

    // MARK: - formattedDate Tests

    @Test("formattedDate returns relative time for recent articles")
    func formattedDateReturnsRelativeTime() {
        // Use a date very close to now for testing relative formatting
        let recentDate = Date().addingTimeInterval(-60) // 1 minute ago

        let article = Article(
            title: "Recent Article",
            source: testSource,
            url: "https://example.com/article",
            publishedAt: recentDate
        )

        let formattedDate = article.formattedDate

        // RelativeDateTimeFormatter with abbreviated style returns strings like "1 min. ago"
        #expect(!formattedDate.isEmpty)
    }

    @Test("formattedDate handles older articles")
    func formattedDateHandlesOlderArticles() {
        let oldDate = Date().addingTimeInterval(-86400 * 7) // 7 days ago

        let article = Article(
            title: "Old Article",
            source: testSource,
            url: "https://example.com/article",
            publishedAt: oldDate
        )

        let formattedDate = article.formattedDate

        #expect(!formattedDate.isEmpty)
    }

    // MARK: - Equatable Tests

    @Test("Article equality compares by all properties")
    func equalityComparison() {
        let article1 = Article(
            id: "same-id",
            title: "Same Title",
            source: testSource,
            url: "https://example.com/article",
            publishedAt: fixedDate
        )

        let article2 = Article(
            id: "same-id",
            title: "Same Title",
            source: testSource,
            url: "https://example.com/article",
            publishedAt: fixedDate
        )

        let article3 = Article(
            id: "different-id",
            title: "Same Title",
            source: testSource,
            url: "https://example.com/article",
            publishedAt: fixedDate
        )

        #expect(article1 == article2)
        #expect(article1 != article3)
    }

    // MARK: - Codable Tests

    @Test("Article encodes and decodes correctly")
    func encodesAndDecodesCorrectly() throws {
        let originalArticle = Article(
            id: "test-id",
            title: "Test Article",
            description: "Test description",
            content: "Full content",
            author: "Author",
            source: testSource,
            url: "https://example.com/article",
            imageURL: "https://example.com/image.jpg",
            publishedAt: fixedDate,
            category: .technology
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalArticle)

        let decoder = JSONDecoder()
        let decodedArticle = try decoder.decode(Article.self, from: data)

        #expect(decodedArticle == originalArticle)
        #expect(decodedArticle.id == originalArticle.id)
        #expect(decodedArticle.title == originalArticle.title)
        #expect(decodedArticle.description == originalArticle.description)
        #expect(decodedArticle.content == originalArticle.content)
        #expect(decodedArticle.author == originalArticle.author)
        #expect(decodedArticle.source == originalArticle.source)
        #expect(decodedArticle.url == originalArticle.url)
        #expect(decodedArticle.imageURL == originalArticle.imageURL)
        #expect(decodedArticle.category == originalArticle.category)
    }

    @Test("Article decodes with nil optional fields")
    func decodesWithNilOptionals() throws {
        let article = Article(
            id: "test-id",
            title: "Minimal Article",
            source: testSource,
            url: "https://example.com/article",
            publishedAt: fixedDate
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(article)

        let decoder = JSONDecoder()
        let decodedArticle = try decoder.decode(Article.self, from: data)

        #expect(decodedArticle.description == nil)
        #expect(decodedArticle.content == nil)
        #expect(decodedArticle.author == nil)
        #expect(decodedArticle.imageURL == nil)
        #expect(decodedArticle.category == nil)
    }

    // MARK: - Hashable Tests

    @Test("Article hashable works correctly")
    func hashableWorks() {
        let article1 = Article(
            id: "same-id",
            title: "Test",
            source: testSource,
            url: "https://example.com",
            publishedAt: fixedDate
        )

        let article2 = Article(
            id: "same-id",
            title: "Test",
            source: testSource,
            url: "https://example.com",
            publishedAt: fixedDate
        )

        var set = Set<Article>()
        set.insert(article1)
        set.insert(article2)

        // Both should hash to the same value since they're equal
        #expect(set.count == 1)
    }

    // MARK: - Identifiable Tests

    @Test("Article conforms to Identifiable")
    func identifiableConformance() {
        let article = Article(
            id: "identifiable-test",
            title: "Test",
            source: testSource,
            url: "https://example.com",
            publishedAt: fixedDate
        )

        #expect(article.id == "identifiable-test")
    }
}

// MARK: - Article Image URL Tests

@Suite("Article Image URL Tests")
struct ArticleImageURLTests {
    private var fixedDate: Date {
        Date(timeIntervalSince1970: 1_672_531_200)
    }

    private var testSource: ArticleSource {
        ArticleSource(id: "test-source", name: "Test News")
    }

    // MARK: - sourceFaviconURL Tests

    @Test("sourceFaviconURL returns correct Google favicon URL")
    func sourceFaviconURLReturnsCorrectURL() {
        let article = Article(
            title: "Test Article",
            source: testSource,
            url: "https://www.nytimes.com/2024/01/01/article",
            publishedAt: fixedDate
        )

        #expect(article.sourceFaviconURL == "https://www.google.com/s2/favicons?domain=www.nytimes.com&sz=128")
    }

    @Test("sourceFaviconURL handles URL without www prefix")
    func sourceFaviconURLHandlesURLWithoutWWW() {
        let article = Article(
            title: "Test Article",
            source: testSource,
            url: "https://techcrunch.com/article",
            publishedAt: fixedDate
        )

        #expect(article.sourceFaviconURL == "https://www.google.com/s2/favicons?domain=techcrunch.com&sz=128")
    }

    @Test("sourceFaviconURL returns nil for invalid URL")
    func sourceFaviconURLReturnsNilForInvalidURL() {
        let article = Article(
            title: "Test Article",
            source: testSource,
            url: "not a valid url",
            publishedAt: fixedDate
        )

        #expect(article.sourceFaviconURL == nil)
    }

    @Test("sourceFaviconURL returns nil for empty URL")
    func sourceFaviconURLReturnsNilForEmptyURL() {
        let article = Article(
            title: "Test Article",
            source: testSource,
            url: "",
            publishedAt: fixedDate
        )

        #expect(article.sourceFaviconURL == nil)
    }

    // MARK: - displayImageURL Tests

    @Test("displayImageURL returns YouTube thumbnail for YouTube video")
    func displayImageURLReturnsYouTubeThumbnail() {
        let article = Article(
            title: "Test Video",
            source: testSource,
            url: "https://example.com",
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: "https://example.com/thumb.jpg",
            publishedAt: fixedDate,
            mediaType: .video,
            mediaURL: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        )

        #expect(article.displayImageURL == "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg")
    }

    @Test("displayImageURL returns thumbnail when no YouTube URL")
    func displayImageURLReturnsThumbnail() {
        let article = Article(
            title: "Test Article",
            source: testSource,
            url: "https://example.com",
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: "https://example.com/thumb.jpg",
            publishedAt: fixedDate
        )

        #expect(article.displayImageURL == "https://example.com/thumb.jpg")
    }

    @Test("displayImageURL returns imageURL when no thumbnail")
    func displayImageURLReturnsImageURL() {
        let article = Article(
            title: "Test Article",
            source: testSource,
            url: "https://example.com",
            imageURL: "https://example.com/image.jpg",
            publishedAt: fixedDate
        )

        #expect(article.displayImageURL == "https://example.com/image.jpg")
    }

    @Test("displayImageURL returns favicon for media without images")
    func displayImageURLReturnsFaviconForMedia() {
        let article = Article(
            title: "Test Podcast",
            source: testSource,
            url: "https://podcasts.example.com/episode",
            publishedAt: fixedDate,
            mediaType: .podcast,
            mediaURL: "https://audio.example.com/episode.mp3"
        )

        #expect(article.displayImageURL == "https://www.google.com/s2/favicons?domain=podcasts.example.com&sz=128")
    }

    @Test("displayImageURL returns nil for regular article without images")
    func displayImageURLReturnsNilForRegularArticle() {
        let article = Article(
            title: "Test Article",
            source: testSource,
            url: "https://example.com/article",
            publishedAt: fixedDate
        )

        #expect(article.displayImageURL == nil)
    }

    // MARK: - heroImageURL Tests

    @Test("heroImageURL returns YouTube thumbnail for YouTube video")
    func heroImageURLReturnsYouTubeThumbnail() {
        let article = Article(
            title: "Test Video",
            source: testSource,
            url: "https://example.com",
            imageURL: "https://example.com/image.jpg",
            thumbnailURL: "https://example.com/thumb.jpg",
            publishedAt: fixedDate,
            mediaType: .video,
            mediaURL: "https://youtu.be/dQw4w9WgXcQ"
        )

        #expect(article.heroImageURL == "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg")
    }

    @Test("heroImageURL returns imageURL over thumbnail")
    func heroImageURLReturnsImageURLOverThumbnail() {
        let article = Article(
            title: "Test Article",
            source: testSource,
            url: "https://example.com",
            imageURL: "https://example.com/full-image.jpg",
            thumbnailURL: "https://example.com/thumb.jpg",
            publishedAt: fixedDate
        )

        #expect(article.heroImageURL == "https://example.com/full-image.jpg")
    }

    @Test("heroImageURL returns thumbnail when no imageURL")
    func heroImageURLReturnsThumbnailWhenNoImageURL() {
        let article = Article(
            title: "Test Article",
            source: testSource,
            url: "https://example.com",
            thumbnailURL: "https://example.com/thumb.jpg",
            publishedAt: fixedDate
        )

        #expect(article.heroImageURL == "https://example.com/thumb.jpg")
    }

    @Test("heroImageURL returns favicon for media without images")
    func heroImageURLReturnsFaviconForMedia() {
        let article = Article(
            title: "Test Video",
            source: testSource,
            url: "https://videos.example.com/watch",
            publishedAt: fixedDate,
            mediaType: .video,
            mediaURL: "https://videos.example.com/video.mp4"
        )

        #expect(article.heroImageURL == "https://www.google.com/s2/favicons?domain=videos.example.com&sz=128")
    }

    @Test("heroImageURL returns nil for regular article without images")
    func heroImageURLReturnsNilForRegularArticle() {
        let article = Article(
            title: "Test Article",
            source: testSource,
            url: "https://example.com/article",
            publishedAt: fixedDate
        )

        #expect(article.heroImageURL == nil)
    }

    // MARK: - isMedia Tests

    @Test("isMedia returns true for video")
    func isMediaReturnsTrueForVideo() {
        let article = Article(
            title: "Test Video",
            source: testSource,
            url: "https://example.com",
            publishedAt: fixedDate,
            mediaType: .video
        )

        #expect(article.isMedia == true)
    }

    @Test("isMedia returns true for podcast")
    func isMediaReturnsTrueForPodcast() {
        let article = Article(
            title: "Test Podcast",
            source: testSource,
            url: "https://example.com",
            publishedAt: fixedDate,
            mediaType: .podcast
        )

        #expect(article.isMedia == true)
    }

    @Test("isMedia returns false for regular article")
    func isMediaReturnsFalseForRegularArticle() {
        let article = Article(
            title: "Test Article",
            source: testSource,
            url: "https://example.com",
            publishedAt: fixedDate
        )

        #expect(article.isMedia == false)
    }
}

// MARK: - ArticleSource Tests

@Suite("ArticleSource Model Tests")
struct ArticleSourceTests {
    @Test("ArticleSource initializes correctly")
    func initializesCorrectly() {
        let source = ArticleSource(id: "source-id", name: "Source Name")

        #expect(source.id == "source-id")
        #expect(source.name == "Source Name")
    }

    @Test("ArticleSource with nil id")
    func initializesWithNilId() {
        let source = ArticleSource(id: nil, name: "Source Name")

        #expect(source.id == nil)
        #expect(source.name == "Source Name")
    }

    @Test("ArticleSource equality")
    func equalityComparison() {
        let source1 = ArticleSource(id: "id", name: "Name")
        let source2 = ArticleSource(id: "id", name: "Name")
        let source3 = ArticleSource(id: "other", name: "Name")

        #expect(source1 == source2)
        #expect(source1 != source3)
    }

    @Test("ArticleSource encodes and decodes")
    func encodesAndDecodes() throws {
        let source = ArticleSource(id: "test", name: "Test Source")

        let encoder = JSONEncoder()
        let data = try encoder.encode(source)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ArticleSource.self, from: data)

        #expect(decoded == source)
    }
}
