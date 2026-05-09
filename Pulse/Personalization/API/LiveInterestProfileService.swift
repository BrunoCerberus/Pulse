import Combine
import Foundation
import SwiftData

/// Live implementation of `InterestProfileService` backed by SwiftData and
/// CloudKit private-DB sync.
///
/// Shares its `ModelContainer` with `LiveStorageService` so the profile rows
/// live in the same store as bookmarks / preferences / reading history and
/// participate in the existing CloudKit sync pipeline. We do **not** spin up
/// a second CloudKit-mirrored container (Apple's `NSPersistentCloudKitContainer`
/// is fragile around multiple instances pointing at the same iCloud zone).
final class LiveInterestProfileService: InterestProfileService {
    private let modelContainer: ModelContainer
    private let changeSubject = PassthroughSubject<Void, Never>()

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    var profileChangedPublisher: AnyPublisher<Void, Never> {
        changeSubject.eraseToAnyPublisher()
    }

    // MARK: - Fetch

    @MainActor
    func fetchProfile() async throws -> [InterestTopic] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<InterestTopicModel>(
            sortBy: [SortDescriptor(\.weight, order: .reverse)]
        )
        let rows = try context.fetch(descriptor)
        return rows.compactMap { $0.toTopic() }
    }

    // MARK: - Upsert / Remove

    @MainActor
    func upsert(
        topicID: String,
        displayName: String,
        weightDelta: Double,
        source: InterestTopic.Source,
        category: String?
    ) async throws {
        let context = modelContainer.mainContext
        let id = topicID
        let descriptor = FetchDescriptor<InterestTopicModel>(
            predicate: #Predicate { $0.topicID == id }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.weight += weightDelta
            existing.lastReinforcedAt = .now
            // Preserve original `displayName` and `source` after first insert
            // (matches the protocol contract). Onboarding seeds rich names
            // like "Artificial Intelligence"; later LLM upserts shouldn't
            // flip the user-facing label every drain. We *do* fill in a
            // missing displayName so a corrupt-or-empty seed still gets a
            // sensible value.
            if existing.displayName.isEmpty, !displayName.isEmpty {
                existing.displayName = displayName
            }
            if let category, existing.category == nil {
                existing.category = category
            }
        } else {
            let topic = InterestTopic(
                topicID: topicID,
                displayName: displayName,
                weight: weightDelta,
                category: category,
                lastReinforcedAt: .now,
                createdAt: .now,
                source: source
            )
            context.insert(InterestTopicModel(from: topic))
        }
        try context.save()
        broadcastChange()
    }

    @MainActor
    func remove(topicID: String) async throws {
        let context = modelContainer.mainContext
        let id = topicID
        let descriptor = FetchDescriptor<InterestTopicModel>(
            predicate: #Predicate { $0.topicID == id }
        )
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
            broadcastChange()
        }
    }

    @MainActor
    func resetProfile() async throws {
        let context = modelContainer.mainContext
        try context.delete(model: InterestTopicModel.self)
        try context.save()
        broadcastChange()
    }

    // MARK: - Seeding

    @MainActor
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

    // MARK: - Change broadcast

    @MainActor
    private func broadcastChange() {
        changeSubject.send(())
        NotificationCenter.default.post(name: .interestProfileDidChange, object: nil)
    }
}
