import SwiftUI

// MARK: - Image Cache

/// A thread-safe in-memory image cache using NSCache with dynamic memory-aware sizing.
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()
    private let urlSession: URLSession
    private var memoryWarningObserver: NSObjectProtocol?

    private init() {
        // Configure URLSession with caching - must be done first before calling methods
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 15 * 1024 * 1024, // 15MB memory
            diskCapacity: 75 * 1024 * 1024, // 75MB disk
            diskPath: "image_cache"
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        urlSession = URLSession(configuration: config)

        // Configure cache limits dynamically based on available memory
        configureCacheLimits()

        // Listen for memory warnings to reduce cache pressure
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }

    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Configures cache limits based on device memory
    private func configureCacheLimits() {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryInGB = Double(totalMemory) / (1024 * 1024 * 1024)

        // Scale cache based on device memory:
        // - Low memory devices (< 3GB): 25 images, 15MB
        // - Medium devices (3-4GB): 50 images, 25MB
        // - High memory devices (> 4GB): 75 images, 30MB
        if memoryInGB < 3 {
            cache.countLimit = 25
            cache.totalCostLimit = 15 * 1024 * 1024
        } else if memoryInGB < 4 {
            cache.countLimit = 50
            cache.totalCostLimit = 25 * 1024 * 1024
        } else {
            cache.countLimit = 75
            cache.totalCostLimit = 30 * 1024 * 1024
        }
    }

    /// Reduces cache size when memory warning is received
    private func handleMemoryWarning() {
        // Immediately clear all cached objects to free memory
        cache.removeAllObjects()
        // Then reduce limits to prevent rapid re-accumulation
        cache.countLimit = max(10, cache.countLimit / 2)
        cache.totalCostLimit = max(5 * 1024 * 1024, cache.totalCostLimit / 2)
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
    let accessibilityLabel: String?

    @State private var image: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        accessibilityLabel: String? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.accessibilityLabel = accessibilityLabel
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
                    .accessibilityLabel(accessibilityLabel ?? "Image")
            } else {
                placeholder()
                    .accessibilityHidden(true)
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
        accessibilityLabel: String? = nil,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(url: url, accessibilityLabel: accessibilityLabel, content: content, placeholder: { ProgressView() })
    }
}

extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?, accessibilityLabel: String? = nil) {
        self.init(url: url, accessibilityLabel: accessibilityLabel, content: { $0 }, placeholder: { ProgressView() })
    }
}
