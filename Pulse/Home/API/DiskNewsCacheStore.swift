import EntropyCore
import Foundation

/// File-based persistent cache implementing `NewsCacheStore`.
///
/// Stores cached articles as JSON files in the system Caches directory,
/// which is purgeable by the OS under storage pressure. Uses a 24-hour
/// TTL (vs 10-min memory TTL) to provide offline fallback data.
///
/// ## Storage Layout
/// ```
/// Caches/PulseNewsCache/
///   ├── headlines_us_p1.json
///   ├── breaking_us.json
///   └── article_<id>.json
/// ```
final class DiskNewsCacheStore: NewsCacheStore {
    /// Wrapper that pairs cached data with a timestamp for TTL validation.
    private struct DiskCacheWrapper: Codable {
        let timestamp: Date
        let payload: Data
    }

    /// Disk TTL: 24 hours (longer than in-memory to serve as offline fallback).
    static let diskTTL: TimeInterval = 24 * 60 * 60

    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(directory: URL? = nil) {
        if let directory {
            cacheDirectory = directory
        } else {
            let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            cacheDirectory = cachesDir.appendingPathComponent("PulseNewsCache", isDirectory: true)
        }

        // Create directory if needed
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }

        // Set file protection so cache is encrypted at rest until first unlock
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: cacheDirectory.path
        )
    }

    func get<T>(for key: NewsCacheKey) -> CacheEntry<T>? {
        let fileURL = fileURL(for: key)

        guard let data = try? Data(contentsOf: fileURL),
              let wrapper = try? decoder.decode(DiskCacheWrapper.self, from: data)
        else {
            return nil
        }

        // Decode payload based on expected type
        if let articles = try? decoder.decode([Article].self, from: wrapper.payload) as? T {
            return CacheEntry(data: articles, timestamp: wrapper.timestamp)
        }
        if let article = try? decoder.decode(Article.self, from: wrapper.payload) as? T {
            return CacheEntry(data: article, timestamp: wrapper.timestamp)
        }

        return nil
    }

    func set<T>(_ entry: CacheEntry<T>, for key: NewsCacheKey) {
        guard let payloadData = encodePayload(entry.data) else { return }

        let wrapper = DiskCacheWrapper(timestamp: entry.timestamp, payload: payloadData)

        guard let wrapperData = try? encoder.encode(wrapper) else { return }

        let fileURL = fileURL(for: key)

        // Atomic write to prevent corruption
        let tempURL = cacheDirectory.appendingPathComponent(UUID().uuidString + ".tmp")
        do {
            try wrapperData.write(to: tempURL, options: .atomic)
            // Move atomically to final location
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            try fileManager.moveItem(at: tempURL, to: fileURL)
        } catch {
            try? fileManager.removeItem(at: tempURL)
            Logger.shared.service("Disk cache write failed for \(key.stringKey): \(error)", level: .debug)
        }
    }

    func remove(for key: NewsCacheKey) {
        let fileURL = fileURL(for: key)
        try? fileManager.removeItem(at: fileURL)
    }

    func removeAll() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }

    // MARK: - Private

    private func fileURL(for key: NewsCacheKey) -> URL {
        // Sanitize key for filesystem: keep only safe characters
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = key.stringKey.unicodeScalars
            .map { allowed.contains($0) ? String($0) : "_" }
            .joined()
        let url = cacheDirectory.appendingPathComponent(sanitized + ".json")
        // Verify the resolved path stays within the cache directory
        guard url.standardizedFileURL.path.hasPrefix(cacheDirectory.standardizedFileURL.path) else {
            return cacheDirectory.appendingPathComponent("invalid_key.json")
        }
        return url
    }

    private func encodePayload(_ data: Any) -> Data? {
        if let articles = data as? [Article] {
            return try? encoder.encode(articles)
        }
        if let article = data as? Article {
            return try? encoder.encode(article)
        }
        return nil
    }
}
