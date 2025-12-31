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
}
