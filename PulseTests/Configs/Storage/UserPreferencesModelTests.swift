import Foundation
@testable import Pulse
import Testing

@Suite("UserPreferencesModel Tests")
struct UserPreferencesModelTests {
    // MARK: - Initialization Tests

    @Test("Init from UserPreferences preserves followed topics")
    func initFromPreferencesPreservesFollowedTopics() {
        let preferences = UserPreferences(
            followedTopics: [.technology, .science, .business],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        let sut = UserPreferencesModel(from: preferences)

        #expect(sut.followedTopics.count == 3)
        #expect(sut.followedTopics.contains("technology"))
        #expect(sut.followedTopics.contains("science"))
        #expect(sut.followedTopics.contains("business"))
    }

    @Test("Init from UserPreferences preserves followed sources")
    func initFromPreferencesPreservesFollowedSources() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: ["BBC", "CNN", "Reuters"],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        let sut = UserPreferencesModel(from: preferences)

        #expect(sut.followedSources == ["BBC", "CNN", "Reuters"])
    }

    @Test("Init from UserPreferences preserves muted sources")
    func initFromPreferencesPreservesMutedSources() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: ["Spam News", "Clickbait Daily"],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        let sut = UserPreferencesModel(from: preferences)

        #expect(sut.mutedSources == ["Spam News", "Clickbait Daily"])
    }

    @Test("Init from UserPreferences preserves muted keywords")
    func initFromPreferencesPreservesMutedKeywords() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: ["politics", "celebrity"],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        let sut = UserPreferencesModel(from: preferences)

        #expect(sut.mutedKeywords == ["politics", "celebrity"])
    }

    @Test("Init from UserPreferences preserves preferred language")
    func initFromPreferencesPreservesPreferredLanguage() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "de",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        let sut = UserPreferencesModel(from: preferences)

        #expect(sut.preferredLanguage == "de")
    }

    @Test("Init from UserPreferences preserves notifications enabled")
    func initFromPreferencesPreservesNotificationsEnabled() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: false,
            breakingNewsNotifications: true
        )

        let sut = UserPreferencesModel(from: preferences)

        #expect(sut.notificationsEnabled == false)
    }

    @Test("Init from UserPreferences preserves breaking news notifications")
    func initFromPreferencesPreservesBreakingNewsNotifications() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: false
        )

        let sut = UserPreferencesModel(from: preferences)

        #expect(sut.breakingNewsNotifications == false)
    }

    // MARK: - toPreferences() Conversion Tests

    @Test("toPreferences reconstructs followed topics")
    func toPreferencesReconstructsFollowedTopics() {
        let preferences = UserPreferences(
            followedTopics: [.technology, .health],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        let sut = UserPreferencesModel(from: preferences)

        let reconstructed = sut.toPreferences()

        #expect(reconstructed.followedTopics == [.technology, .health])
    }

    @Test("toPreferences reconstructs followed sources")
    func toPreferencesReconstructsFollowedSources() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: ["Source1", "Source2"],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        let sut = UserPreferencesModel(from: preferences)

        let reconstructed = sut.toPreferences()

        #expect(reconstructed.followedSources == ["Source1", "Source2"])
    }

    @Test("toPreferences reconstructs muted sources")
    func toPreferencesReconstructsMutedSources() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: ["Muted1"],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        let sut = UserPreferencesModel(from: preferences)

        let reconstructed = sut.toPreferences()

        #expect(reconstructed.mutedSources == ["Muted1"])
    }

    @Test("toPreferences reconstructs muted keywords")
    func toPreferencesReconstructsMutedKeywords() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: ["keyword1", "keyword2"],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        let sut = UserPreferencesModel(from: preferences)

        let reconstructed = sut.toPreferences()

        #expect(reconstructed.mutedKeywords == ["keyword1", "keyword2"])
    }

    @Test("toPreferences reconstructs preferred language")
    func toPreferencesReconstructsPreferredLanguage() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "fr",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        let sut = UserPreferencesModel(from: preferences)

        let reconstructed = sut.toPreferences()

        #expect(reconstructed.preferredLanguage == "fr")
    }

    @Test("toPreferences reconstructs notifications enabled")
    func toPreferencesReconstructsNotificationsEnabled() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: false,
            breakingNewsNotifications: true
        )
        let sut = UserPreferencesModel(from: preferences)

        let reconstructed = sut.toPreferences()

        #expect(reconstructed.notificationsEnabled == false)
    }

    @Test("toPreferences reconstructs breaking news notifications")
    func toPreferencesReconstructsBreakingNewsNotifications() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: false
        )
        let sut = UserPreferencesModel(from: preferences)

        let reconstructed = sut.toPreferences()

        #expect(reconstructed.breakingNewsNotifications == false)
    }

    // MARK: - Empty Array Tests

    @Test("Handles empty followed topics")
    func handlesEmptyFollowedTopics() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        let sut = UserPreferencesModel(from: preferences)

        #expect(sut.followedTopics.isEmpty)
        #expect(sut.toPreferences().followedTopics.isEmpty)
    }

    @Test("Handles empty muted sources")
    func handlesEmptyMutedSources() {
        let preferences = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        let sut = UserPreferencesModel(from: preferences)

        #expect(sut.mutedSources.isEmpty)
        #expect(sut.toPreferences().mutedSources.isEmpty)
    }

    // MARK: - Roundtrip Tests

    @Test("Full roundtrip preserves all data")
    func fullRoundtripPreservesAllData() {
        let original = UserPreferences(
            followedTopics: [.technology, .science, .sports],
            followedSources: ["BBC", "CNN"],
            mutedSources: ["Spam"],
            mutedKeywords: ["clickbait", "sponsored"],
            preferredLanguage: "es",
            notificationsEnabled: false,
            breakingNewsNotifications: true
        )

        let model = UserPreferencesModel(from: original)
        let reconstructed = model.toPreferences()

        #expect(reconstructed.followedTopics == original.followedTopics)
        #expect(reconstructed.followedSources == original.followedSources)
        #expect(reconstructed.mutedSources == original.mutedSources)
        #expect(reconstructed.mutedKeywords == original.mutedKeywords)
        #expect(reconstructed.preferredLanguage == original.preferredLanguage)
        #expect(reconstructed.notificationsEnabled == original.notificationsEnabled)
        #expect(reconstructed.breakingNewsNotifications == original.breakingNewsNotifications)
    }

    // MARK: - Invalid Topic Handling

    @Test("toPreferences filters invalid topic strings")
    func toPreferencesFiltersInvalidTopicStrings() {
        let preferences = UserPreferences(
            followedTopics: [.technology],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        let model = UserPreferencesModel(from: preferences)

        // Manually add an invalid topic string
        model.followedTopics.append("invalid_topic")

        let reconstructed = model.toPreferences()

        // Should only contain valid topics
        #expect(reconstructed.followedTopics.count == 1)
        #expect(reconstructed.followedTopics.contains(.technology))
    }
}
