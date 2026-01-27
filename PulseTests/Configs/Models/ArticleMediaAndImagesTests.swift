import Foundation
@testable import Pulse
import Testing

@Suite("Article Media + Image URL Tests")
struct ArticleMediaAndImagesTests {
    private let fixedDate = Date(timeIntervalSince1970: 1_672_531_200) // Jan 1, 2023
    private let testSource = ArticleSource(id: "test-source", name: "Test News")

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
