import CryptoKit
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

    /// HMAC-SHA256 signature (hex-encoded) computed over the URL string
    /// using a signing key shared between the extension and main app via
    /// App Group `UserDefaults`.
    ///
    /// When present, the main app verifies this signature before draining
    /// the queue (SEC-006). When absent (legacy items, or when no key is
    /// configured), the item is accepted without verification for backward
    /// compatibility.
    var signature: String?
}

extension SharedURLItem {
    /// Factory for constructing a signed queue item from the Share Extension.
    /// The caller passes the URL string and the pre-computed signature from
    /// `SharedURLQueue.signURL(_:)`.
    static func makingSigned(url: String, sharedAt: Date, signature: String?) -> Self {
        var item = Self(url: url, sharedAt: sharedAt)
        item.signature = signature
        return item
    }
}

/// HMAC signing key stored in App Group `UserDefaults`.
///
/// The key is generated on first use and shared between the main app and
/// the Share Extension via App Group (the extension cannot access Keychain
/// — no `keychain-access-groups` entitlement). This provides HMAC integrity
/// at the IPC boundary, mitigating tampering from jailbroken devices or
/// forensic modification of App Group data (SEC-006).
private enum SharedURLHMACKey {
    /// `UserDefaults` key for the HMAC signing key string.
    static let keyDefaultsKey = "pulse.sharedURLQueueHMACKey"

    /// The shared App Group identifier.
    static let appGroupIdentifier = "group.com.bruno.Pulse-News"

    /// Generates or retrieves the HMAC signing key from App Group
    /// `UserDefaults`. If no key exists, generates a cryptographically
    /// secure random 32-byte key and stores it.
    static func getOrCreateKey() -> Data? {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        if let existing = defaults.data(forKey: keyDefaultsKey) {
            return existing
        }
        let key = RandomDataGenerator.randomBytes(count: 32)
        _ = defaults.set(key, forKey: keyDefaultsKey)
        return key
    }
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
///
/// Starting with iOS 26, items are signed with an HMAC-SHA256 digest
/// (SEC-006) using a random key stored in App Group. The Share Extension
/// signs items using this key; the main app verifies signatures when the
/// key is configured, and accepts unsigned items when verification is
/// unavailable (backward compatibility).
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
    /// allow-listed scheme. Rejects path-traversal (`..`) in the path component
    /// and any URL containing control characters, matching the defense-in-depth
    /// strategy applied to deeplink parameters (rule 16). Exposed at file scope
    /// so the producer side (`ShareViewController`) and consumer side
    /// (`LiveSharedURLImportService`) can apply the same rule for defense in depth.
    static func isAcceptable(urlString: String) -> Bool {
        guard !urlString.isEmpty,
              urlString.count <= maxURLLength,
              let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              allowedSchemes.contains(scheme)
        else { return false }
        // Reject path-traversal sequences that could escape the intended scope.
        guard !url.pathComponents.contains("..") else {
            return false
        }
        // Reject URLs whose string form contains control characters (could be
        // obfuscation vectors or lead to malformed payloads). This mirrors the
        // control-char stripping applied in `PromptSanitizer` and deeplink
        // parameter sanitization (rule 16).
        for scalar in urlString.unicodeScalars where CharacterSet.controlCharacters.contains(scalar) {
            return false
        }
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

    // MARK: - HMAC Verification (SEC-006)

    /// Returns an HMAC-SHA256 signature for a URL string using the shared
    /// App Group key. Called by the Share Extension when signing items.
    static func signURL(_ urlString: String) -> String? {
        guard let key = SharedURLHMACKey.getOrCreateKey() else { return nil }
        let message = urlString.data(using: .utf8) ?? Data()
        let symKey = SymmetricKey(data: key)
        let hmac = HMAC<SHA256>.authenticationCode(for: message, using: symKey)
        return hmac.withUnsafeBytes { bytes in
            Array(bytes).map { String(format: "%02x", $0) }.joined()
        }
    }

    /// Verifies that a `SharedURLItem`'s signature matches its URL string.
    ///
    /// Returns `true` when:
    /// - The item has no signature (legacy format): accepted for backward
    ///   compatibility.
    /// - The item has a signature AND the shared key is configured AND
    ///   the signature verifies.
    ///
    /// Returns `false` when:
    /// - The item has a signature but verification fails (tampered URL).
    /// - The item has a signature but the shared key is unavailable.
    static func verifyItem(_ item: SharedURLItem) -> Bool {
        guard let signature = item.signature else {
            // Unsigned (legacy): accept for backward compatibility.
            return true
        }
        guard let computed = Self.signURL(item.url) else { return false }
        return SecureEqual.sequal(computed, signature)
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

private enum SecureEqual {
    /// Whether two hex-encoded HMAC strings are equal, using constant-time
    /// comparison to prevent timing side-channels.
    static func sequal(_ hexA: String, _ hexB: String) -> Bool {
        guard hexA.count == hexB.count else { return false }
        var diff: UInt8 = 0
        for (charA, charB) in zip(hexA.utf8, hexB.utf8) {
            diff |= charA ^ charB
        }
        return diff == 0
    }
}

private enum RandomDataGenerator {
    /// Generates `count` cryptographically secure random bytes.
    static func randomBytes(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }
}
