import Combine
import EntropyCore
import Foundation
import SwiftData

// MARK: - Live Storage Service

final class LiveStorageService: StorageService {
    /// iCloud container backing CloudKit-synced SwiftData.
    /// Must match the `com.apple.developer.icloud-container-identifiers` entitlement.
    static let cloudKitContainerIdentifier = "iCloud.com.bruno.Pulse-News"

    /// Exposed (module-internal) so other CloudKit-synced services in the
    /// `Personalization` module — e.g. `LiveInterestProfileService` — can
    /// share the same container without each of them spinning up their own
    /// CloudKit-mirrored store. Outside this module the container is not
    /// reachable.
    let modelContainer: ModelContainer

    /// Device-local-only SwiftData container for non-synced models.
    ///
    /// `ReadArticle` and `InterestTopicModel` are device-local personalization
    /// data that must never reach CloudKit (SEC-002). This container has no
    /// CloudKit mirror and is not shared with the CloudKit-synced services.
    ///
    /// Exposed via `deviceLocalContainer` so other services (e.g.
    /// `LiveInterestProfileService`) can access the same non-synced store
    /// without creating their own.
    let deviceLocalContainer: ModelContainer

    /// - Parameters:
    ///   - inMemory: When `true`, uses an in-memory store (for tests). Forces
    ///     CloudKit off regardless of `enableCloudKit`.
    ///   - enableCloudKit: When `true` (and not `inMemory`), mirrors the store
    ///     to the private CloudKit database at `cloudKitContainerIdentifier`.
    ///
    /// ## Data Protection
    ///
    /// SwiftData inherits the iOS-default file protection class
    /// `.completeUntilFirstUserAuthentication`. This is intentional: the
    /// CloudKit-mirroring layer must be able to read and write the store
    /// while the device is locked (background push delivery, silent
    /// notifications, periodic sync). Promoting the store to `.complete`
    /// would break those flows. Sensitive *fields* (read history) should be
    /// protected by App Lock + the privacy overlay added in `RootView`,
    /// not by the file-protection class on a synced store.
    init(inMemory: Bool = false, enableCloudKit: Bool = true) {
        do {
            // CloudKit-synced models: bookmarks and user preferences.
            let syncedSchema = Schema([
                BookmarkedArticle.self,
                UserPreferencesModel.self,
            ])
            let syncedConfiguration = if inMemory || !enableCloudKit {
                ModelConfiguration(schema: syncedSchema, isStoredInMemoryOnly: inMemory)
            } else {
                ModelConfiguration(
                    schema: syncedSchema,
                    cloudKitDatabase: .private(Self.cloudKitContainerIdentifier),
                )
            }
            modelContainer = try ModelContainer(for: syncedSchema, configurations: [syncedConfiguration])

            // Device-local-only models: reading history and personalization
            // topics. These must never reach CloudKit (SEC-002).
            // Uses a dedicated store URL to avoid the "two schemas on one file"
            // pitfall that causes SwiftData to lightweight-migrate the store
            // down to the newer schema, deleting tables owned by the other.
            let deviceLocalSchema = Schema([
                ReadArticle.self,
                InterestTopicModel.self,
            ])
            let deviceLocalConfiguration: ModelConfiguration
            if inMemory {
                deviceLocalConfiguration = ModelConfiguration(
                    schema: deviceLocalSchema,
                    isStoredInMemoryOnly: true,
                )
            } else {
                let storeURL = URL.applicationSupportDirectory.appending(
                    path: "pulse_deviceLocal.store",
                )
                deviceLocalConfiguration = ModelConfiguration(
                    schema: deviceLocalSchema,
                    url: storeURL,
                )
            }
            deviceLocalContainer = try ModelContainer(
                for: deviceLocalSchema,
                configurations: [deviceLocalConfiguration],
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    @MainActor
    func saveArticle(_ article: Article) async throws {
        let context = modelContainer.mainContext
        let articleID = article.id
        let descriptor = FetchDescriptor<BookmarkedArticle>(
            predicate: #Predicate { $0.articleID == articleID },
        )
        if try context.fetch(descriptor).first != nil {
            return
        }
        let bookmarked = BookmarkedArticle(from: article)
        context.insert(bookmarked)
        try context.save()
    }

    @MainActor
    func deleteArticle(_ article: Article) async throws {
        let context = modelContainer.mainContext
        let articleID = article.id
        let descriptor = FetchDescriptor<BookmarkedArticle>(
            predicate: #Predicate { $0.articleID == articleID },
        )
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }

    @MainActor
    func fetchBookmarkedArticles() async throws -> [Article] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<BookmarkedArticle>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)],
        )
        let bookmarked = try context.fetch(descriptor)
        return bookmarked.map { $0.toArticle() }
    }

    @MainActor
    func isBookmarked(_ articleID: String) async -> Bool {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<BookmarkedArticle>(
            predicate: #Predicate { $0.articleID == articleID },
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    @MainActor
    func saveUserPreferences(_ preferences: UserPreferences) async throws {
        let context = modelContainer.mainContext
        try context.delete(model: UserPreferencesModel.self)
        let model = UserPreferencesModel(from: preferences)
        context.insert(model)
        try context.save()
    }

    @MainActor
    func fetchUserPreferences() async throws -> UserPreferences? {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<UserPreferencesModel>()
        return try context.fetch(descriptor).first?.toPreferences()
    }

    // MARK: - Reading History

    @MainActor
    func markArticleAsRead(_ article: Article) async throws {
        let context = deviceLocalContainer.mainContext
        let articleID = article.id
        let descriptor = FetchDescriptor<ReadArticle>(
            predicate: #Predicate { $0.articleID == articleID },
        )
        if let existing = try context.fetch(descriptor).first {
            existing.readAt = .now
        } else {
            context.insert(ReadArticle(from: article))
        }
        try context.save()
    }

    @MainActor
    func isRead(_ articleID: String) async -> Bool {
        let context = deviceLocalContainer.mainContext
        let descriptor = FetchDescriptor<ReadArticle>(
            predicate: #Predicate { $0.articleID == articleID },
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    @MainActor
    func fetchReadArticleIDs() async throws -> Set<String> {
        let context = deviceLocalContainer.mainContext
        let descriptor = FetchDescriptor<ReadArticle>()
        let readArticles = try context.fetch(descriptor)
        return Set(readArticles.map(\.articleID))
    }

    @MainActor
    func fetchReadArticles() async throws -> [Article] {
        let context = deviceLocalContainer.mainContext
        let descriptor = FetchDescriptor<ReadArticle>(
            sortBy: [SortDescriptor(\.readAt, order: .reverse)],
        )
        let readArticles = try context.fetch(descriptor)
        return readArticles.map { $0.toArticle() }
    }

    @MainActor
    func clearReadingHistory() async throws {
        let context = deviceLocalContainer.mainContext
        try context.delete(model: ReadArticle.self)
        try context.save()
    }

    // MARK: - Data Cleanup

    @MainActor
    func clearBookmarks() async throws {
        let context = modelContainer.mainContext
        try context.delete(model: BookmarkedArticle.self)
        try context.save()
    }

    @MainActor
    func clearUserPreferences() async throws {
        let context = modelContainer.mainContext
        try context.delete(model: UserPreferencesModel.self)
        try context.save()
    }

    @MainActor
    func clearAllUserData() async throws {
        try await clearBookmarks()
        try await clearUserPreferences()
        try await clearReadingHistory()
    }

    // MARK: - Deduplication

    /// Collapses duplicate `BookmarkedArticle` / `ReadArticle` rows that
    /// `NSPersistentCloudKitContainer` can produce by merging same-`articleID`
    /// rows from multiple devices (H8). Uniqueness here is service-enforced
    /// (no `@Attribute(.unique)`, which CloudKit forbids), so a cross-device
    /// merge can leave two rows for one article; this folds each group down to
    /// the earliest-saved / earliest-read survivor and deletes the rest, with a
    /// single `save()` at the end.
    ///
    /// Runs after a CloudKit sync completes: `CloudSyncDomainInteractor` invokes
    /// it on `.cloudSyncDidComplete` and re-posts the notification when rows were
    /// collapsed so Bookmarks / Reading History reload the cleaned data.
    @MainActor
    @discardableResult
    func deduplicate() async throws -> Bool {
        var changed = false

        // Deduplicate bookmarks in the CloudKit-synced container.
        if try await deduplicateBookmarks() {
            changed = true
        }

        // Deduplicate reading history in the device-local container.
        if try await deduplicateReadingHistory() {
            changed = true
        }

        return changed
    }

    @MainActor
    private func deduplicateBookmarks() async throws -> Bool {
        let context = modelContainer.mainContext
        var didChange = false

        let bookmarks = try context.fetch(FetchDescriptor<BookmarkedArticle>())
        var keptBookmarks: [String: BookmarkedArticle] = [:]
        for row in bookmarks {
            if let kept = keptBookmarks[row.articleID] {
                let earlier = kept.savedAt <= row.savedAt ? kept : row
                let later = kept.savedAt <= row.savedAt ? row : kept
                context.delete(later)
                keptBookmarks[row.articleID] = earlier
                didChange = true
            } else {
                keptBookmarks[row.articleID] = row
            }
        }

        guard didChange else { return false }
        try context.save()
        return true
    }

    @MainActor
    private func deduplicateReadingHistory() async throws -> Bool {
        let context = deviceLocalContainer.mainContext
        var didChange = false

        let reads = try context.fetch(FetchDescriptor<ReadArticle>())
        var keptReads: [String: ReadArticle] = [:]
        for row in reads {
            if let kept = keptReads[row.articleID] {
                let earlier = kept.readAt <= row.readAt ? kept : row
                let later = kept.readAt <= row.readAt ? row : kept
                context.delete(later)
                keptReads[row.articleID] = earlier
                didChange = true
            } else {
                keptReads[row.articleID] = row
            }
        }

        guard didChange else { return false }
        try context.save()
        return true
    }
}
