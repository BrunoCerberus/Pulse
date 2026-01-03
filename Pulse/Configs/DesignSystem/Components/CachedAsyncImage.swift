import SwiftUI

// MARK: - Image Cache

/// A thread-safe in-memory image cache using NSCache.
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()
    private let urlSession: URLSession

    private init() {
        // Configure cache limits
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB

        // Configure URLSession with caching
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024, // 20MB memory
            diskCapacity: 100 * 1024 * 1024, // 100MB disk
            diskPath: "image_cache"
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        urlSession = URLSession(configuration: config)
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func setImage(_ image: UIImage, for url: URL) {
        let cost = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }

    func loadImage(from url: URL) async throws -> UIImage {
        // Check memory cache first
        if let cached = image(for: url) {
            return cached
        }

        // Fetch from network (URLSession handles disk cache)
        let (data, _) = try await urlSession.data(from: url)

        guard let image = UIImage(data: data) else {
            throw ImageCacheError.invalidImageData
        }

        // Store in memory cache
        setImage(image, for: url)

        return image
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}

enum ImageCacheError: Error {
    case invalidImageData
}

// MARK: - Cached Async Image

/// An AsyncImage replacement with built-in caching support.
/// Uses both memory (NSCache) and disk (URLCache) caching.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard !isLoading, image == nil, let url else { return }

        // Check memory cache synchronously
        if let cached = ImageCache.shared.image(for: url) {
            image = cached
            return
        }

        isLoading = true

        Task {
            do {
                let loadedImage = try await ImageCache.shared.loadImage(from: url)
                await MainActor.run {
                    image = loadedImage
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Convenience Initializers

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(url: url, content: content, placeholder: { ProgressView() })
    }
}

extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?) {
        self.init(url: url, content: { $0 }, placeholder: { ProgressView() })
    }
}
