import EntropyCore
@testable import Pulse
import SwiftUI
import Testing

// MARK: - AudioBriefingGateView Tests

@Suite("AudioBriefingGateView Tests")
@MainActor
struct AudioBriefingGateViewTests {
    @Test("Localization keys exist and resolve to non-empty strings")
    func localizationKeysResolve() {
        let title = AppLocalization.localized("feed.audio_briefing_gate.title")
        let description = AppLocalization.localized("feed.audio_briefing_gate.description")
        let unlockButton = AppLocalization.localized("feed.audio_briefing_gate.unlock_button")

        #expect(!title.isEmpty, "Briefing gate title should not be empty")
        #expect(!description.isEmpty, "Briefing gate description should not be empty")
        #expect(!unlockButton.isEmpty, "Unlock button text should not be empty")
    }

    @Test("PremiumFeature.audioBriefing has correct icon name")
    func audioBriefingEnumHasCorrectIcon() {
        #expect(PremiumFeature.audioBriefing.icon == "headphones")
    }

    @Test("FeedView constants include briefing-related strings")
    func feedConstantsIncludeBriefingStrings() {
        let title = AppLocalization.localized("feed.listen_briefing")
        let hint = AppLocalization.localized("feed.listen_briefing_hint")

        #expect(!title.isEmpty, "Listen briefing string should not be empty")
        #expect(!hint.isEmpty, "Listen briefing hint should not be empty")
    }
}

// MARK: - Localization Bundle Tests

@Suite("Audio Briefing Localization Bundle Tests")
@MainActor
struct AudioBriefingLocalizationBundleTests {
    private static let briefingKeys = [
        "feed.audio_briefing_gate.title",
        "feed.audio_briefing_gate.description",
        "feed.audio_briefing_gate.unlock_button",
    ]

    private static let locales: [String] = ["en", "pt", "es"]

    @Test("Briefing gate strings exist in all localization bundles")
    func briefingStringsInAllBundles() {
        for localeCode in Self.locales {
            guard let bundlePath = Bundle.main.path(
                forResource: localeCode,
                ofType: "lproj"
            ) else {
                Issue.record("No bundle found for locale: \(localeCode)")
                continue
            }

            let bundle = Bundle(path: bundlePath)
            #expect(bundle != nil, "Bundle for locale \(localeCode) should exist")

            guard let bundle else { continue }

            for key in Self.briefingKeys {
                let value = bundle.localizedString(forKey: key, value: nil, table: nil)
                #expect(value != key && !value.isEmpty, "Key '\(key)' should have a non-empty value in \(localeCode)")
            }
        }
    }
}

// MARK: - FeedView Empty State Tests

@Suite("FeedView Empty State Tests")
@MainActor
struct FeedViewEmptyStateTests {
    @Test("Empty state constants resolve from localization")
    func emptyStateConstantsResolve() {
        #expect(!FeedView.Constants.emptyTitle.isEmpty)
        #expect(!FeedView.Constants.emptyMessage.isEmpty)
    }

    @Test("PremiumFeature.audioBriefing enum case exists")
    func premiumFeatureAudioBriefingExists() {
        let feature = PremiumFeature.audioBriefing
        #expect(feature.icon == "headphones")
    }
}
