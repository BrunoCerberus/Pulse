import Foundation
@testable import Pulse
import Testing

@Suite("UserPreferencesModel Conversion Tests")
struct UserPreferencesModelConversionTests {
    // MARK: - toPreferences() Conversion Tests

    @Test("toPreferences reconstructs followed topics")
    func toPreferencesReconstructsFollowedTopics() {
        let preferences = UserPreferences(
            followedTopics: [.technology, .health],

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

    @Test("toPreferences reconstructs muted sources")
    func toPreferencesReconstructsMutedSources() {
        let preferences = UserPreferences(
            followedTopics: [],

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

    // MARK: - Roundtrip Tests

    @Test("Full roundtrip preserves all data")
    func fullRoundtripPreservesAllData() {
        let original = UserPreferences(
            followedTopics: [.technology, .science, .sports],
            mutedSources: ["Spam"],
            mutedKeywords: ["clickbait", "sponsored"],
            preferredLanguage: "es",
            notificationsEnabled: false,
            breakingNewsNotifications: true
        )

        let model = UserPreferencesModel(from: original)
        let reconstructed = model.toPreferences()

        #expect(reconstructed.followedTopics == original.followedTopics)
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
