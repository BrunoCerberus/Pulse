import Foundation
@testable import Pulse
import Testing

@Suite("UserPreferences Tests")
struct UserPreferencesTests {
    @Test("Default preferences have correct values")
    func defaultPreferences() {
        let prefs = UserPreferences.default

        #expect(prefs.followedTopics.isEmpty)
        #expect(prefs.notificationsEnabled == false)
        #expect(prefs.breakingNewsNotifications == false)
        #expect(prefs.mutedSources.isEmpty)
        #expect(prefs.mutedKeywords.isEmpty)
    }

    @Test("Preferences can be created with custom values")
    func customPreferences() {
        let prefs = UserPreferences(
            followedTopics: [.technology, .business],
            notificationsEnabled: true,
            breakingNewsNotifications: true,
            mutedSources: ["Source A"],
            mutedKeywords: ["spam"]
        )

        #expect(prefs.followedTopics.count == 2)
        #expect(prefs.notificationsEnabled == true)
        #expect(prefs.breakingNewsNotifications == true)
        #expect(prefs.mutedSources.count == 1)
        #expect(prefs.mutedKeywords.count == 1)
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
        prefs1.notificationsEnabled = true

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
}
