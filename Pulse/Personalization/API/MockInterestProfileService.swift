import Combine
import Foundation

/// In-memory mock of `InterestProfileService` for unit / preview tests.
///
/// Stores topics keyed by `topicID` in a dictionary so upsert mirrors the
/// Live behavior (single row per topicID). Exposes `topics` for direct
/// assertion and error-injection knobs matching the convention used by
/// `MockStorageService` / `MockEngagementEventsService`.
final class MockInterestProfileService: InterestProfileService, @unchecked Sendable {
    private var storage: [String: InterestTopic] = [:]
    private let changeSubject = PassthroughSubject<Void, Never>()

    var fetchProfileError: Error?
    var upsertError: Error?
    var removeError: Error?

    /// Snapshot of all stored topics, sorted by weight descending.
    var topics: [InterestTopic] {
        storage.values.sorted { $0.weight > $1.weight }
    }

    var profileChangedPublisher: AnyPublisher<Void, Never> {
        changeSubject.eraseToAnyPublisher()
    }

    func fetchProfile() async throws -> [InterestTopic] {
        if let fetchProfileError {
            throw fetchProfileError
        }
        return topics
    }

    func upsert(
        topicID: String,
        displayName: String,
        weightDelta: Double,
        source: InterestTopic.Source,
        category: String?
    ) async throws {
        if let upsertError {
            throw upsertError
        }
        if let existing = storage[topicID] {
            storage[topicID] = InterestTopic(
                topicID: existing.topicID,
                displayName: displayName,
                weight: existing.weight + weightDelta,
                category: category ?? existing.category,
                lastReinforcedAt: .now,
                createdAt: existing.createdAt,
                source: existing.source
            )
        } else {
            storage[topicID] = InterestTopic(
                topicID: topicID,
                displayName: displayName,
                weight: weightDelta,
                category: category,
                lastReinforcedAt: .now,
                createdAt: .now,
                source: source
            )
        }
        broadcastChange()
    }

    func remove(topicID: String) async throws {
        if let removeError {
            throw removeError
        }
        if storage.removeValue(forKey: topicID) != nil {
            broadcastChange()
        }
    }

    func resetProfile() async throws {
        storage = [:]
        broadcastChange()
    }

    func seedFromCategories(_ categories: [NewsCategory]) async throws {
        for category in categories {
            try await upsert(
                topicID: category.rawValue,
                displayName: category.displayName,
                weightDelta: 1.0,
                source: .seed,
                category: category.rawValue
            )
        }
    }

    private func broadcastChange() {
        changeSubject.send(())
        NotificationCenter.default.post(name: .interestProfileDidChange, object: nil)
    }
}
