import Combine
import Foundation

/// Protocol defining the persistent interest-profile store.
///
/// The profile is a flat list of `InterestTopic` rows accumulating per-topic
/// weights. Mutations broadcast via `profileChangedPublisher` (and a
/// `Notification.Name.interestProfileDidChange` post) so the For You surface
/// and Settings page can reload from storage.
///
/// ## Thread Safety
/// All mutating operations are `async`; implementations may be `@MainActor`
/// (matching `StorageService`). Callers wrap the service in
/// `UncheckedSendableBox` when crossing `Task` boundaries.
protocol InterestProfileService {
    /// Returns every topic in the profile, sorted by weight descending.
    func fetchProfile() async throws -> [InterestTopic]

    /// Upserts a topic by `topicID`, accumulating `weightDelta` onto any
    /// existing weight and bumping `lastReinforcedAt` to now. The first
    /// upsert sets `createdAt` and `source`; later upserts preserve the
    /// original `source` (so an LLM-extracted topic doesn't get downgraded
    /// to "seed" later, etc.).
    ///
    /// - Parameters:
    ///   - topicID: Lowercase kebab-case stable identifier.
    ///   - displayName: Human-readable name, refreshed on every upsert.
    ///   - weightDelta: Amount to add to the stored weight (signed).
    ///   - source: Provenance for the *first* insert only.
    ///   - category: Optional `NewsCategory.rawValue` for canonical seeds.
    func upsert(
        topicID: String,
        displayName: String,
        weightDelta: Double,
        source: InterestTopic.Source,
        category: String?,
    ) async throws

    /// Removes a single topic. No-op if `topicID` doesn't exist.
    func remove(topicID: String) async throws

    /// Wipes every topic. Called from `SettingsViewModel.clearAllUserData`
    /// on sign-out / account deletion.
    func resetProfile() async throws

    /// Convenience seeder that upserts one row per `NewsCategory` with
    /// `source = .seed` and `weight = 1.0`. Called once at the end of
    /// onboarding.
    func seedFromCategories(_ categories: [NewsCategory]) async throws

    /// Collapses duplicate `InterestTopicModel` rows that a cross-device
    /// `NSPersistentCloudKitContainer` merge can leave (uniqueness is
    /// service-enforced, not `@Attribute(.unique)`). Folds duplicate weights
    /// into the earliest-created survivor. Intended to run after a CloudKit
    /// sync completes.
    /// - Returns: `true` if any duplicate rows were removed, `false` otherwise.
    func deduplicate() async throws -> Bool

    /// Emits each time the profile is mutated (every upsert / remove /
    /// reset / seed). Safe to ignore; the corresponding
    /// `Notification.Name.interestProfileDidChange` is also posted for
    /// non-Combine subscribers.
    var profileChangedPublisher: AnyPublisher<Void, Never> { get }
}
