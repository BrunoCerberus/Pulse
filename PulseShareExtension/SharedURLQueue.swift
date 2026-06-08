import Foundation

/// A URL item queued by the Share Extension for the main app to process.
///
/// This model is shared between the Share Extension and the main app via
/// the App Group container, allowing the extension to enqueue URLs for
/// later summarization while keeping the LLM workload in the main process.
struct SharedURLItem: Codable, Hashable {
    /// The shared URL as an absolute string.
    let url: String

    /// Timestamp when the URL was shared from the extension.
    let sharedAt: Date
}

/// Thread-safe FIFO queue persisted in App Group `UserDefaults`.
///
/// The Share Extension cannot run the on-device LLM (model size exceeds
/// the ~120MB extension memory budget), so it appends `SharedURLItem`
/// records to this queue and exits. The main app drains the queue on
/// foreground via `SharedURLImportService.processPendingItems()`.
///
/// JSON encoding is used so the data layout is forward-compatible if the
/// queue ever needs to be inspected from a non-Swift context.
struct SharedURLQueue: @unchecked Sendable {
    /// Identifier for the App Group shared between Pulse and its extensions.
    static let appGroupIdentifier = "group.com.bruno.Pulse-News"

    /// `UserDefaults` key under which the encoded queue is stored.
    static let queueKey = "pulse.pendingSharedURLs"

    /// Hard cap on the number of items kept in the queue. The Share Extension can run
    /// before the main app has registered a drain handler for `pulse://shared`, so a
    /// runaway producer (e.g. user shares 1000 articles in a row) must not be allowed
    /// to bloat App Group `UserDefaults`. When the cap is exceeded, the oldest entries
    /// are dropped (FIFO eviction).
    static let maxQueueSize = 50

    /// Hard cap on the length of any single URL string accepted into the queue.
    /// 2048 chars covers every practical web URL while bounding `UserDefaults`
    /// memory pressure and serialization cost. URLs longer than this are rejected
    /// rather than truncated — truncation would silently corrupt the link.
    static let maxURLLength = 2048

    /// Schemes accepted by `enqueue`. Anything else (`javascript:`, `data:`,
    /// `file:`, custom schemes) is rejected at the queue boundary so a malicious
    /// or buggy producer can't smuggle non-web URLs to the main app.
    static let allowedSchemes: Set<String> = ["http", "https"]

    /// Backing defaults store. Optional to allow safe handling of a
    /// missing/misconfigured App Group at runtime.
    let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: SharedURLQueue.appGroupIdentifier)) {
        self.defaults = defaults
    }

    /// Append an item to the tail of the queue.
    ///
    /// Rejects items whose URL string exceeds `maxURLLength`, has an
    /// unparseable URL, or uses a scheme outside `allowedSchemes`.
    /// If the queue would exceed `maxQueueSize` after the append, the oldest
    /// entries are dropped (FIFO eviction).
    ///
    /// - Returns: `true` if persistence succeeded, `false` if the item was
    ///   rejected, the App Group is unavailable, or the write failed.
    @discardableResult
    func enqueue(_ item: SharedURLItem) -> Bool {
        guard defaults != nil else { return false }
        guard Self.isAcceptable(urlString: item.url) else { return false }
        var current = readQueue()
        current.append(item)
        if current.count > Self.maxQueueSize {
            current.removeFirst(current.count - Self.maxQueueSize)
        }
        return writeQueue(current)
    }

    /// Validates that a URL string is short enough, parseable, and uses an
    /// allow-listed scheme. Exposed at file scope so the producer side
    /// (`ShareViewController`) and consumer side (`LiveSharedURLImportService`)
    /// can apply the same rule for defense in depth.
    static func isAcceptable(urlString: String) -> Bool {
        guard !urlString.isEmpty,
              urlString.count <= maxURLLength,
              let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              allowedSchemes.contains(scheme)
        else { return false }
        return true
    }

    /// Returns all queued items in FIFO order without removing them.
    func peekAll() -> [SharedURLItem] {
        readQueue()
    }

    /// Removes and returns the oldest item in the queue, if any.
    /// Not `mutating`: the only state lives in `UserDefaults`, not in `self`.
    func dequeue() -> SharedURLItem? {
        guard defaults != nil else { return nil }
        var current = readQueue()
        guard !current.isEmpty else { return nil }
        let head = current.removeFirst()
        _ = writeQueue(current)
        return head
    }

    /// Removes all items and returns them in FIFO order.
    /// Not `mutating`: the only state lives in `UserDefaults`, not in `self`.
    func drain() -> [SharedURLItem] {
        let snapshot = readQueue()
        guard !snapshot.isEmpty else { return [] }
        clear()
        return snapshot
    }

    /// Removes all items from the queue.
    func clear() {
        defaults?.removeObject(forKey: SharedURLQueue.queueKey)
    }

    // MARK: - Private

    private func readQueue() -> [SharedURLItem] {
        guard let defaults,
              let data = defaults.data(forKey: SharedURLQueue.queueKey)
        else {
            return []
        }
        do {
            let decoded = try JSONDecoder().decode([SharedURLItem].self, from: data)
            // Symmetric with `enqueue`'s write-side cap: the `maxQueueSize`
            // invariant is re-applied on read so a tampered or oversized payload
            // written directly to the App Group key (first-party/jailbreak only)
            // can't make the main app decode an unbounded array. Keep the newest
            // items (FIFO eviction of the oldest), matching `enqueue`.
            return decoded.count > Self.maxQueueSize
                ? Array(decoded.suffix(Self.maxQueueSize))
                : decoded
        } catch {
            // Treat corrupted payloads as empty so a single bad write does
            // not block future enqueues. The extension cannot log here.
            return []
        }
    }

    @discardableResult
    private func writeQueue(_ items: [SharedURLItem]) -> Bool {
        guard let defaults else { return false }
        do {
            let data = try JSONEncoder().encode(items)
            defaults.set(data, forKey: SharedURLQueue.queueKey)
            return true
        } catch {
            return false
        }
    }
}
