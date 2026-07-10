import Foundation

/// Persists when Smart Briefing was last served and which article IDs it
/// has already queued, so re-tapping the button doesn't repeat articles.
///
/// Backed by `UserDefaults`, not SwiftData (mirrors `BriefingCacheService`):
/// a single, disposable record, device-local — each device tracks its own
/// "already heard" set rather than syncing it via CloudKit.
protocol SmartBriefingCacheService {
    /// Persists a run's served record, replacing any prior entry.
    func store(_ record: SmartBriefingServedRecord)

    /// Returns the most recent served record, or `nil` if Smart Briefing has
    /// never been run.
    func fetchLastServed() -> SmartBriefingServedRecord?

    /// Wipes the record. Called from sign-out/account-deletion cleanup.
    func clear()
}

/// A single Smart Briefing run's outcome: when it ran and which articles it
/// served, so the next run can exclude them and report "last briefed" in the UI.
struct SmartBriefingServedRecord: Codable, Equatable {
    let servedAt: Date
    let servedArticleIDs: Set<String>
}

final class LiveSmartBriefingCacheService: SmartBriefingCacheService {
    /// Exposed (not `private`) so sign-out/account-deletion cleanup
    /// (`SettingsViewModel.clearAllUserData()`) can wipe this key without
    /// duplicating the literal string.
    static let storageKey = "pulse.smartBriefingServedRecord"

    /// Caps the served-ID history so the UserDefaults blob doesn't grow
    /// unbounded across months of daily use. Stored internally as an
    /// ordered list (oldest first) so capping actually evicts the oldest
    /// IDs, then exposed as a `Set` at the protocol boundary for call-site
    /// convenience.
    private let maxServedIDs = 500

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func store(_ record: SmartBriefingServedRecord) {
        var orderedIDs = fetchOrderedServedIDs()
        orderedIDs.removeAll { record.servedArticleIDs.contains($0) }
        orderedIDs.append(contentsOf: record.servedArticleIDs)
        if orderedIDs.count > maxServedIDs {
            orderedIDs.removeFirst(orderedIDs.count - maxServedIDs)
        }

        let stored = StoredRecord(servedAt: record.servedAt, orderedServedArticleIDs: orderedIDs)
        guard let data = try? JSONEncoder().encode(stored) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    func fetchLastServed() -> SmartBriefingServedRecord? {
        guard let stored = fetchStoredRecord() else { return nil }
        return SmartBriefingServedRecord(
            servedAt: stored.servedAt,
            servedArticleIDs: Set(stored.orderedServedArticleIDs)
        )
    }

    func clear() {
        defaults.removeObject(forKey: Self.storageKey)
    }

    private func fetchOrderedServedIDs() -> [String] {
        fetchStoredRecord()?.orderedServedArticleIDs ?? []
    }

    private func fetchStoredRecord() -> StoredRecord? {
        guard let data = defaults.data(forKey: Self.storageKey) else { return nil }
        return try? JSONDecoder().decode(StoredRecord.self, from: data)
    }

    private struct StoredRecord: Codable {
        let servedAt: Date
        let orderedServedArticleIDs: [String]
    }
}
