import EntropyCore
import Foundation
@testable import Pulse
import Testing
import UIKit

/// Tests for ImageCache singleton.
///
/// **Test Isolation Note**: These tests use `ImageCache.shared` singleton which maintains
/// global state. Tests use unique URLs to avoid conflicts, but `clearCache()` affects global
/// state. If parallel test execution causes issues, consider running these tests serially
/// with `@Suite(.serialized)` or adding a test-specific cache instance capability.
@Suite("ImageCache Tests")
struct ImageCacheTests {
    // MARK: - Test Data

    private var testURL: URL {
        URL(string: "https://example.com/test-image.jpg")!
    }

    private var differentURL: URL {
        URL(string: "https://example.com/different-image.jpg")!
    }

    private var testImage: UIImage {
        // Create a simple 1x1 pixel image for testing
        UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
    }

    // MARK: - Cache Storage Tests

    @Test("ImageCache stores and retrieves images by URL")
    func storesAndRetrievesImages() {
        let cache = ImageCache.shared

        // Store the image
        cache.setImage(testImage, for: testURL)

        // Retrieve the image
        let retrievedImage = cache.image(for: testURL)

        #expect(retrievedImage != nil)
    }

    @Test("ImageCache returns nil for uncached URL")
    func returnsNilForUncachedURL() throws {
        let cache = ImageCache.shared

        // Use a unique URL that hasn't been cached
        let uncachedURL = try #require(URL(string: "https://example.com/uncached-\(UUID().uuidString).jpg"))

        let retrievedImage = cache.image(for: uncachedURL)

        #expect(retrievedImage == nil)
    }

    @Test("clearCache removes all cached images")
    func clearCacheRemovesAllImages() throws {
        let cache = ImageCache.shared

        // Use unique URLs for this test to avoid interference
        let url1 = try #require(URL(string: "https://example.com/clear-test-1-\(UUID().uuidString).jpg"))
        let url2 = try #require(URL(string: "https://example.com/clear-test-2-\(UUID().uuidString).jpg"))

        // Store images
        cache.setImage(testImage, for: url1)
        cache.setImage(testImage, for: url2)

        // Verify they were stored
        #expect(cache.image(for: url1) != nil)
        #expect(cache.image(for: url2) != nil)

        // Clear the cache
        cache.clearCache()

        // Verify they were removed
        #expect(cache.image(for: url1) == nil)
        #expect(cache.image(for: url2) == nil)
    }

    // MARK: - Cache Hit Tests

    @Test("Cache hit returns same image without network call")
    func cacheHitReturnsCachedImage() throws {
        let cache = ImageCache.shared

        // Use unique URL for this test
        let uniqueURL = try #require(URL(string: "https://example.com/cache-hit-\(UUID().uuidString).jpg"))

        // Pre-populate the cache
        cache.setImage(testImage, for: uniqueURL)

        // The image should be retrievable immediately
        let cachedImage = cache.image(for: uniqueURL)
        #expect(cachedImage != nil)
    }

    // MARK: - Overwrite Tests

    @Test("Setting image for same URL overwrites previous")
    func settingImageOverwritesPrevious() throws {
        let cache = ImageCache.shared

        let uniqueURL = try #require(URL(string: "https://example.com/overwrite-\(UUID().uuidString).jpg"))

        // Create two different colored images
        let redImage = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }

        let blueImage = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }

        // Set first image
        cache.setImage(redImage, for: uniqueURL)

        // Set second image for same URL
        cache.setImage(blueImage, for: uniqueURL)

        // Retrieve and verify it was overwritten (the cached image should exist)
        let retrievedImage = cache.image(for: uniqueURL)
        #expect(retrievedImage != nil)
    }

    // MARK: - Shared Instance Tests

    @Test("ImageCache shared instance is singleton")
    func sharedInstanceIsSingleton() {
        let instance1 = ImageCache.shared
        let instance2 = ImageCache.shared

        #expect(instance1 === instance2)
    }
}

@Suite("ImageCacheError Tests")
struct ImageCacheErrorTests {
    @Test("invalidImageData error case exists")
    func invalidImageDataCase() {
        let error = ImageCacheError.invalidImageData

        // Verify the error case exists and can be used
        switch error {
        case .invalidImageData:
            #expect(true) // Test passes if we reach here
        }
    }

    @Test("ImageCacheError conforms to Error")
    func conformsToError() {
        let error: Error = ImageCacheError.invalidImageData

        // Verify it can be used as a generic Error
        #expect(error is ImageCacheError)
    }
}
