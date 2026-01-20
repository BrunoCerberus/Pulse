import Foundation
@testable import Pulse
import Testing

@Suite("UserPreferences Initialization Tests")
struct UserPreferencesInitializationTests {
    @Test("Can create UserPreferences with default values")
    func userPreferencesInitialization() {
        let prefs = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        #expect(prefs.followedTopics.isEmpty)
        #expect(prefs.followedSources.isEmpty)
        #expect(prefs.mutedSources.isEmpty)
        #expect(prefs.mutedKeywords.isEmpty)
        #expect(prefs.preferredLanguage == "en")
        #expect(prefs.notificationsEnabled == true)
        #expect(prefs.breakingNewsNotifications == true)
    }

    @Test("Can create UserPreferences with topics and sources")
    func userPreferencesWithTopicsAndSources() {
        let prefs = UserPreferences(
            followedTopics: [.world, .technology],
            followedSources: ["The Guardian", "BBC News"],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        #expect(prefs.followedTopics.count == 2)
        #expect(prefs.followedSources.count == 2)
        #expect(prefs.followedTopics.contains(.world))
        #expect(prefs.followedTopics.contains(.technology))
    }

    @Test("Can create UserPreferences with muted content")
    func userPreferencesWithMutedContent() {
        let prefs = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: ["Tabloid A", "Tabloid B"],
            mutedKeywords: ["celebrity", "gossip"],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        #expect(prefs.mutedSources.count == 2)
        #expect(prefs.mutedKeywords.count == 2)
        #expect(prefs.mutedSources.contains("Tabloid A"))
        #expect(prefs.mutedKeywords.contains("celebrity"))
    }

    @Test("Can create UserPreferences with notifications disabled")
    func userPreferencesNotificationsDisabled() {
        let prefs = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: false,
            breakingNewsNotifications: false
        )

        #expect(prefs.notificationsEnabled == false)
        #expect(prefs.breakingNewsNotifications == false)
    }

    @Test("Can specify different language")
    func userPreferencesDifferentLanguage() {
        let prefs = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "fr",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        #expect(prefs.preferredLanguage == "fr")
    }
}

@Suite("UserPreferences Default Tests")
struct UserPreferencesDefaultTests {
    @Test("Default preferences has empty collections")
    func defaultPreferencesEmpty() {
        let prefs = UserPreferences.default

        #expect(prefs.followedTopics.isEmpty)
        #expect(prefs.followedSources.isEmpty)
        #expect(prefs.mutedSources.isEmpty)
        #expect(prefs.mutedKeywords.isEmpty)
    }

    @Test("Default preferences enables notifications")
    func defaultPreferencesNotificationsEnabled() {
        let prefs = UserPreferences.default

        #expect(prefs.notificationsEnabled == true)
        #expect(prefs.breakingNewsNotifications == true)
    }

    @Test("Default preferences uses current locale language")
    func defaultPreferencesLanguage() {
        let prefs = UserPreferences.default

        #expect(!prefs.preferredLanguage.isEmpty)
        // Default should be based on current locale
        let expectedLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        #expect(prefs.preferredLanguage == expectedLanguage)
    }
}

@Suite("UserPreferences Equatable Tests")
struct UserPreferencesEquatableTests {
    @Test("Same preferences are equal")
    func samePreferencesEqual() {
        let prefs1 = UserPreferences(
            followedTopics: [.world],
            followedSources: ["BBC"],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        let prefs2 = UserPreferences(
            followedTopics: [.world],
            followedSources: ["BBC"],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        #expect(prefs1 == prefs2)
    }

    @Test("Different topics make preferences not equal")
    func differentTopicsNotEqual() {
        let prefs1 = UserPreferences(
            followedTopics: [.world],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        let prefs2 = UserPreferences(
            followedTopics: [.technology],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        #expect(prefs1 != prefs2)
    }

    @Test("Different notification settings make preferences not equal")
    func differentNotificationsNotEqual() {
        let prefs1 = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
        let prefs2 = UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: false,
            breakingNewsNotifications: true
        )

        #expect(prefs1 != prefs2)
    }
}

@Suite("UserPreferences Mutability Tests")
struct UserPreferencesmutabilityTests {
    @Test("Can modify followed topics")
    func modifyFollowedTopics() {
        var prefs = UserPreferences.default
        prefs.followedTopics = [.world, .technology]

        #expect(prefs.followedTopics.count == 2)
        #expect(prefs.followedTopics.contains(.world))
    }

    @Test("Can add to followed sources")
    func modifyFollowedSources() {
        var prefs = UserPreferences.default
        prefs.followedSources = ["BBC", "CNN"]

        #expect(prefs.followedSources.count == 2)
    }

    @Test("Can modify muted sources")
    func modifyMutedSources() {
        var prefs = UserPreferences.default
        prefs.mutedSources = ["Tabloid"]

        #expect(prefs.mutedSources.count == 1)
        #expect(prefs.mutedSources.contains("Tabloid"))
    }

    @Test("Can modify muted keywords")
    func modifyMutedKeywords() {
        var prefs = UserPreferences.default
        prefs.mutedKeywords = ["celebrity", "gossip"]

        #expect(prefs.mutedKeywords.count == 2)
    }

    @Test("Can disable notifications")
    func disableNotifications() {
        var prefs = UserPreferences.default
        prefs.notificationsEnabled = false
        prefs.breakingNewsNotifications = false

        #expect(prefs.notificationsEnabled == false)
        #expect(prefs.breakingNewsNotifications == false)
    }

    @Test("Can change language")
    func changeLanguage() {
        var prefs = UserPreferences.default
        prefs.preferredLanguage = "es"

        #expect(prefs.preferredLanguage == "es")
    }
}

@Suite("UserPreferences Codable Tests")
struct UserPreferencesCodableTests {
    @Test("Can encode UserPreferences")
    func userPreferencesEncodable() throws {
        let prefs = UserPreferences(
            followedTopics: [.world, .technology],
            followedSources: ["BBC"],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(prefs)
        #expect(!data.isEmpty)
    }

    @Test("Can decode UserPreferences")
    func userPreferencesDecodable() throws {
        let prefs = UserPreferences(
            followedTopics: [.world, .technology],
            followedSources: ["BBC"],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(prefs)

        let decoder = JSONDecoder()
        let decodedPrefs = try decoder.decode(UserPreferences.self, from: data)

        #expect(decodedPrefs == prefs)
    }

    @Test("Preserves all fields through encoding/decoding")
    func preferencesRoundTrip() throws {
        let prefs = UserPreferences(
            followedTopics: [.world, .technology, .science],
            followedSources: ["BBC", "CNN", "Reuters"],
            mutedSources: ["Tabloid A", "Tabloid B"],
            mutedKeywords: ["celebrity", "gossip", "drama"],
            preferredLanguage: "es",
            notificationsEnabled: false,
            breakingNewsNotifications: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(prefs)

        let decoder = JSONDecoder()
        let decodedPrefs = try decoder.decode(UserPreferences.self, from: data)

        #expect(decodedPrefs.followedTopics.count == 3)
        #expect(decodedPrefs.followedSources.count == 3)
        #expect(decodedPrefs.mutedSources.count == 2)
        #expect(decodedPrefs.mutedKeywords.count == 3)
        #expect(decodedPrefs.preferredLanguage == "es")
        #expect(decodedPrefs.notificationsEnabled == false)
        #expect(decodedPrefs.breakingNewsNotifications == true)
    }
}

@Suite("UserPreferences Integration Tests")
struct UserPreferencesIntegrationTests {
    @Test("Can update preferences and maintain consistency")
    func updatePreferencesConsistency() {
        var prefs = UserPreferences.default

        // Follow topics
        prefs.followedTopics = [.world, .technology]
        #expect(prefs.followedTopics.count == 2)

        // Add muted sources
        prefs.mutedSources = ["Tabloid"]
        #expect(prefs.mutedSources.count == 1)

        // Disable notifications
        prefs.notificationsEnabled = false

        // Verify all changes persisted
        #expect(prefs.followedTopics.count == 2)
        #expect(prefs.mutedSources.count == 1)
        #expect(prefs.notificationsEnabled == false)
    }

    @Test("Default preferences can be customized")
    func customizeDefaultPreferences() {
        var prefs = UserPreferences.default

        prefs.followedTopics.append(.business)
        prefs.followedTopics.append(.health)

        #expect(prefs.followedTopics.count == 2)
        #expect(prefs.notificationsEnabled == true)
    }

    @Test("Can create multiple distinct preference sets")
    func multiplePreferenceSets() {
        let newsAddict = UserPreferences(
            followedTopics: NewsCategory.allCases,
            followedSources: ["BBC", "CNN", "Reuters"],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )

        let selectiveReader = UserPreferences(
            followedTopics: [.technology],
            followedSources: ["Tech Daily"],
            mutedSources: ["Tabloid"],
            mutedKeywords: ["celebrity"],
            preferredLanguage: "en",
            notificationsEnabled: false,
            breakingNewsNotifications: false
        )

        #expect(newsAddict.followedTopics.count > selectiveReader.followedTopics.count)
        #expect(newsAddict.notificationsEnabled != selectiveReader.notificationsEnabled)
    }
}
