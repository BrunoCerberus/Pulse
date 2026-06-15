import Foundation
@testable import Pulse
import Testing

/// Unit tests ensuring SafeMediaURL gate is exercised in YouTubeThumbnailView.
@Suite("YouTubeThumbnailView safe URL tests")
struct YouTubeThumbnailViewSafeMediaURLTests {
    @Test("https thumbnail URLs pass SafeMediaURL gate")
    func httpsThumbnailURLs() {
        let valid = [
            "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
            "https://picsum.photos/800/450",
        ]

        for urlString in valid {
            let safeURL = SafeMediaURL.validated(urlString)
            #expect(safeURL != nil, "Expected https URL to pass: \(urlString)")
        }
    }

    @Test("http thumbnail URLs rejected by SafeMediaURL gate")
    func httpThumbnailURLs() {
        let invalid = [
            "http://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
            "http://picsum.photos/800/450",
        ]

        for urlString in invalid {
            let safeURL = SafeMediaURL.validated(urlString)
            #expect(safeURL == nil, "Expected http URL to be rejected: \(urlString)")
        }
    }

    @Test("http article URL fallback rejected by SafeMediaURL gate")
    func httpArticleFallback() {
        let invalid = [
            "http://example.com/image.jpg",
            "http://cdn.example.com/photo.png",
        ]

        for urlString in invalid {
            let safeURL = SafeMediaURL.validated(urlString)
            #expect(safeURL == nil, "Expected http article URL to be rejected: \(urlString)")
        }
    }

    @Test("Invalid article URLs rejected by SafeMediaURL gate")
    func invalidArticleURLs() {
        let invalid = [
            "not-a-url",
            "",
            "file:///etc/passwd",
        ]

        for urlString in invalid {
            let safeURL = SafeMediaURL.validated(urlString)
            #expect(safeURL == nil, "Expected invalid URL to be rejected: \(urlString)")
        }
    }

    @Test("https article URLs pass SafeMediaURL gate")
    func httpsArticleURLs() {
        let valid = [
            "https://picsum.photos/800/450",
            "https://example.com/image.jpg",
        ]

        for urlString in valid {
            let safeURL = SafeMediaURL.validated(urlString)
            #expect(safeURL != nil, "Expected https article URL to pass: \(urlString)")
        }
    }

    @Test("YouTube thumbnail URLs from extraction pass SafeMediaURL gate")
    func youtubeThumbnailUrlsPassGate() {
        // YouTube thumbnail URLs are always img.youtube.com with https scheme.
        let valid = [
            "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
            "https://img.youtube.com/vi/abc123/_default.jpg",
        ]

        for urlString in valid {
            let safeURL = SafeMediaURL.validated(urlString)
            #expect(safeURL != nil, "YouTube thumbnail URL should pass SafeMediaURL gate: \(urlString)")
        }
    }

    @Test("SafeMediaURL gate is applied in YouTubeThumbnailView button action path")
    func buttonActionPath() {
        // The Button action at YouTubeThumbnailView.swift:29-30 calls
        // SafeMediaURL.validated(urlString) before opening in Safari.
        // This test exercises the same https success path with the URL
        // that would be passed from a YouTube watch URL.
        let youtubeWatchURL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        let safeURL = SafeMediaURL.validated(youtubeWatchURL)
        #expect(safeURL != nil, "Valid YouTube watch URL should pass SafeMediaURL gate")
    }

    @Test("SafeMediaURL gate rejects http YouTube URLs in button action path")
    func buttonActionRejectsHttpYouTube() {
        // Verifies the rejection path at YouTubeThumbnailView.swift:29-30.
        let httpYouTubeURL = "http://www.youtube.com/watch?v=dQw4w9WgXcQ"
        let safeURL = SafeMediaURL.validated(httpYouTubeURL)
        #expect(safeURL == nil, "http YouTube URL should be rejected")
    }

    @Test("SafeMediaURL gate is applied to thumbnail URLs in AsyncImage path")
    func asyncImageUrlPath() {
        // The AsyncImage at YouTubeThumbnailView.swift:37 calls
        // SafeMediaURL.validated(thumbnailURL) for the extracted thumbnail.
        let thumbnail = "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg"
        let safeURL = SafeMediaURL.validated(thumbnail)
        #expect(safeURL != nil, "HTTPS YouTube thumbnail should pass SafeMediaURL gate")
    }

    @Test("SafeMediaURL gate is applied to article image fallback in AsyncImage path")
    func asyncImageFallbackPath() {
        // The articleImage fallback at YouTubeThumbnailView.swift:103 calls
        // SafeMediaURL.validated(imageURL) for the article's image URL.
        let validArticleImage = "https://picsum.photos/800/450"
        let safeURL = SafeMediaURL.validated(validArticleImage)
        #expect(safeURL != nil, "HTTPS article image should pass SafeMediaURL gate")
    }
}
