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
            sortBy: [SortDescriptor(\.weight, order: .reverse)],
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
        category: String?,
    ) async throws {
        let context = modelContainer.mainContext
        try upsertWithoutSave(
            in: context,
            topicID: topicID,
            displayName: displayName,
            weightDelta: weightDelta,
            source: source,
            category: category,
        )
        try context.save()
        broadcastChange()
    }

    /// Upserts a batch of topics with a **single** `save()` + `broadcastChange()`
    /// at the end (M14). `seedFromCategories` and the drainer's `applyTags` use
    /// this so each call doesn't fan out into N saves / N notifications / N
    /// `ForYou` rescores. No-op (no save, no broadcast) when `topics` is empty.
    @MainActor
    func upsertMany(_ topics: [InterestTopicUpsert]) async throws {
        guard !topics.isEmpty else { return }
        let context = modelContainer.mainContext
        for topic in topics {
            try upsertWithoutSave(
                in: context,
                topicID: topic.topicID,
                displayName: topic.displayName,
                weightDelta: topic.weightDelta,
                source: topic.source,
                category: topic.category,
            )
        }
        try context.save()
        broadcastChange()
    }

    /// Dedupe-tolerant upsert without persisting (H8 + M14). CloudKit can merge
    /// a remote row for the same `topicID` from another device, leaving
    /// duplicate `InterestTopicModel` rows; folding all matches into a single
    /// survivor here keeps weights from double-counting. Callers own the
    /// `save()` + `broadcastChange()`.
    @MainActor
    // swiftlint:disable:next function_parameter_count
    private func upsertWithoutSave(
        in context: ModelContext,
        topicID: String,
        displayName: String,
        weightDelta: Double,
        source: InterestTopic.Source,
        category: String?,
    ) throws {
        let id = topicID
        let descriptor = FetchDescriptor<InterestTopicModel>(
            predicate: #Predicate { $0.topicID == id },
        )

        let matches = try context.fetch(descriptor)
        if let existing = matches.first {
            existing.weight += weightDelta
            existing.lastReinforcedAt = .now
            // Fold any CloudKit-merged duplicates into the survivor so their
            // accumulated weight isn't lost (and isn't double-counted on the
            // next upsert that only ever touched `.first`).
            for dup in matches.dropFirst() {
                existing.weight += dup.weight
                context.delete(dup)
            }
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
                source: source,
            )
            context.insert(InterestTopicModel(from: topic))
        }
    }

    @MainActor
    func remove(topicID: String) async throws {
        let context = modelContainer.mainContext
        let id = topicID
        let descriptor = FetchDescriptor<InterestTopicModel>(
            predicate: #Predicate { $0.topicID == id },
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

    // MARK: - Deduplication

    /// Collapses duplicate `InterestTopicModel` rows that `NSPersistentCloudKitContainer`
    /// may have produced by merging same-`topicID` rows from multiple devices
    /// (H8). Groups by `topicID`, keeps the oldest row (smallest `createdAt`),
    /// folds the duplicates' weights into it, and deletes the rest. Single
    /// `save()` + `broadcastChange()` at the end (and only if anything changed).
    ///
    /// Runs after a CloudKit sync completes: `CloudSyncDomainInteractor` invokes
    /// it on `.cloudSyncDidComplete` and re-broadcasts so the For You surface and
    /// Settings reload the collapsed profile.
    @MainActor
    @discardableResult
    func deduplicate() async throws -> Bool {
        let context = modelContainer.mainContext
        let rows = try context.fetch(FetchDescriptor<InterestTopicModel>())

        var survivors: [String: InterestTopicModel] = [:]
        var didChange = false
        for row in rows {
            if let survivor = survivors[row.topicID] {
                // Keep the earliest-created row as the survivor; fold weight.
                let earlier = survivor.createdAt <= row.createdAt ? survivor : row
                let later = survivor.createdAt <= row.createdAt ? row : survivor
                earlier.weight += later.weight
                context.delete(later)
                survivors[row.topicID] = earlier
                didChange = true
            } else {
                survivors[row.topicID] = row
            }
        }

        guard didChange else { return false }
        try context.save()
        broadcastChange()
        return true
    }

    // MARK: - Seeding

    @MainActor
    func seedFromCategories(_ categories: [NewsCategory]) async throws {
        // Batched: one save + one broadcast for the whole seed set (M14),
        // instead of one per category.
        try await upsertMany(
            categories.map { category in
                InterestTopicUpsert(
                    topicID: category.rawValue,
                    displayName: category.displayName,
                    weightDelta: 1.0,
                    source: .seed,
                    category: category.rawValue,
                )
            },
        )
    }

    // MARK: - Change broadcast

    @MainActor
    private func broadcastChange() {
        changeSubject.send(())
        NotificationCenter.default.post(name: .interestProfileDidChange, object: nil)
    }
}

/// Parameters for one entry in a batched `upsertMany` call. Mirrors the
/// arguments of the single `upsert(...)` so the bulk and single paths share
/// the same dedupe-tolerant logic without multiplying saves / broadcasts (M14).
struct InterestTopicUpsert {
    let topicID: String
    let displayName: String
    let weightDelta: Double
    let source: InterestTopic.Source
    let category: String?
}
