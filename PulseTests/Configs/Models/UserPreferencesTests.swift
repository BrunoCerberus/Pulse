import Foundation
@testable import Pulse
import Testing

@Suite("UserPreferences Tests")
struct UserPreferencesTests {
    @Test("Default preferences have correct values")
    func defaultPreferences() {
        let prefs = UserPreferences.default

        #expect(prefs.followedTopics.isEmpty)
        #expect(prefs.mutedSources.isEmpty)
        #expect(prefs.mutedKeywords.isEmpty)
        #expect(prefs.notificationsEnabled == true)
        #expect(prefs.breakingNewsNotifications == true)
        #expect(!prefs.preferredLanguage.isEmpty)
    }

    @Test("Preferences can be created with custom values")
    func customPreferences() {
        let prefs = UserPreferences(
            followedTopics: [.technology, .business],
            mutedSources: ["Source A"],
            mutedKeywords: ["spam"],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        #expect(prefs.followedTopics.count == 2)
        #expect(prefs.mutedSources.count == 1)
        #expect(prefs.mutedKeywords.count == 1)
        #expect(prefs.preferredLanguage == "en")
        #expect(prefs.notificationsEnabled == true)
        #expect(prefs.breakingNewsNotifications == true)
    }

    @Test("Same preferences are equal")
    func samePreferencesAreEqual() {
        let prefs1 = UserPreferences.default
        let prefs2 = UserPreferences.default

        #expect(prefs1 == prefs2)
    }

    @Test("Different followedTopics are not equal")
    func differentFollowedTopics() {
        var prefs1 = UserPreferences.default
        prefs1.followedTopics = [.technology]

        var prefs2 = UserPreferences.default
        prefs2.followedTopics = [.business]

        #expect(prefs1 != prefs2)
    }

    @Test("Different notificationsEnabled are not equal")
    func differentNotificationsEnabled() {
        var prefs1 = UserPreferences.default
        prefs1.notificationsEnabled = false

        let prefs2 = UserPreferences.default

        #expect(prefs1 != prefs2)
    }

    @Test("Different mutedSources are not equal")
    func differentMutedSources() {
        var prefs1 = UserPreferences.default
        prefs1.mutedSources = ["Source A"]

        let prefs2 = UserPreferences.default

        #expect(prefs1 != prefs2)
    }

    @Test("Different preferredLanguage are not equal")
    func differentPreferredLanguage() {
        var prefs1 = UserPreferences.default
        prefs1.preferredLanguage = "fr"

        let prefs2 = UserPreferences.default

        // Only different if default language wasn't "fr"
        if prefs2.preferredLanguage != "fr" {
            #expect(prefs1 != prefs2)
        }
    }
}
