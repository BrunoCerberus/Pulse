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

    /// Serializes all filesystem access so a single shared instance can be safely
    /// used by both caching services without torn reads or `removeAll`/`set` races.
    private let ioQueue = DispatchQueue(label: "com.pulse.diskcache")

    /// - Important: Register **one** shared instance in production (see
    ///   `PulseSceneDelegate.registerLiveServices()`) and inject it into every
    ///   `Caching*Service`. `ioQueue` serializes I/O *within* an instance, but
    ///   two instances pointing at the same `directory` each have their own queue
    ///   and would race on the filesystem. The `directory` parameter exists for
    ///   test isolation (a unique temp dir per test); production passes `nil` to
    ///   use the shared Caches path.
    init(directory: URL? = nil) {
        if let directory {
            cacheDirectory = directory
        } else if let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            cacheDirectory = cachesDir.appendingPathComponent("PulseNewsCache", isDirectory: true)
        } else {
            Logger.shared.service("Caches directory not found, using temp directory", level: .warning)
            cacheDirectory = fileManager.temporaryDirectory.appendingPathComponent("PulseNewsCache", isDirectory: true)
        }

        // Create directory if needed
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                Logger.shared.service("Failed to create disk cache directory: \(error)", level: .warning)
            }
        }

        // Set file protection. The cache is only read while the app is foregrounded
        // (no background sync, no widget reads), so `.complete` is safe and gives the
        // strongest at-rest protection — files are unreadable while the device is locked.
        //
        // The directory attribute applies to *new* files written here (and to the
        // directory itself). Files already on disk from a prior version retain their
        // original protection class until rewritten — so we also walk existing
        // entries and re-apply the attribute one-time, making the upgrade transparent.
        applyCompleteProtection(to: cacheDirectory)
    }

    /// Set `.complete` protection on a directory and every file already inside it.
    /// Best-effort — failures are logged at `.warning` so a lone unwritable file
    /// doesn't prevent the cache from operating.
    private func applyCompleteProtection(to directory: URL) {
        do {
            try fileManager.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: directory.path
            )
        } catch {
            Logger.shared.service("Failed to set file protection on cache directory: \(error)", level: .warning)
        }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else { return }

        for url in contents {
            do {
                try fileManager.setAttributes(
                    [.protectionKey: FileProtectionType.complete],
                    ofItemAtPath: url.path
                )
            } catch {
                Logger.shared.service(
                    "Failed to upgrade file protection on \(url.lastPathComponent): \(error)",
                    level: .warning
                )
            }
        }
    }

    func get<T>(for key: NewsCacheKey) -> CacheEntry<T>? {
        ioQueue.sync {
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
    }

    func set<T>(_ entry: CacheEntry<T>, for key: NewsCacheKey) {
        ioQueue.sync {
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
    }

    func remove(for key: NewsCacheKey) {
        ioQueue.sync {
            let fileURL = fileURL(for: key)
            guard fileManager.fileExists(atPath: fileURL.path) else { return }
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                Logger.shared.service("Disk cache remove failed for \(key.stringKey): \(error)", level: .debug)
            }
        }
    }

    func removeAll() {
        ioQueue.sync {
            let files: [URL]
            do {
                files = try fileManager.contentsOfDirectory(
                    at: cacheDirectory,
                    includingPropertiesForKeys: nil
                )
            } catch {
                Logger.shared.service("Failed to list disk cache directory: \(error)", level: .warning)
                return
            }

            for file in files {
                do {
                    try fileManager.removeItem(at: file)
                } catch {
                    Logger.shared.service(
                        "Disk cache cleanup failed for \(file.lastPathComponent): \(error)",
                        level: .debug
                    )
                }
            }
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
