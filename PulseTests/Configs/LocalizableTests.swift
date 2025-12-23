import Foundation
@testable import Pulse
import Testing

@Suite("Localizable Tests")
struct LocalizableTests {
    // MARK: - Paywall Loading Tests

    @Test("Loading string is not empty")
    func loadingStringIsNotEmpty() {
        #expect(!Localizable.paywall.loading.isEmpty)
    }

    // MARK: - Paywall Title/Subtitle Tests

    @Test("Title string is not empty")
    func titleStringIsNotEmpty() {
        #expect(!Localizable.paywall.title.isEmpty)
    }

    @Test("Subtitle string is not empty")
    func subtitleStringIsNotEmpty() {
        #expect(!Localizable.paywall.subtitle.isEmpty)
    }

    // MARK: - Feature 1 Tests

    @Test("Feature 1 title is not empty")
    func feature1TitleIsNotEmpty() {
        #expect(!Localizable.paywall.feature1Title.isEmpty)
    }

    @Test("Feature 1 description is not empty")
    func feature1DescriptionIsNotEmpty() {
        #expect(!Localizable.paywall.feature1Description.isEmpty)
    }

    // MARK: - Feature 2 Tests

    @Test("Feature 2 title is not empty")
    func feature2TitleIsNotEmpty() {
        #expect(!Localizable.paywall.feature2Title.isEmpty)
    }

    @Test("Feature 2 description is not empty")
    func feature2DescriptionIsNotEmpty() {
        #expect(!Localizable.paywall.feature2Description.isEmpty)
    }

    // MARK: - Feature 3 Tests

    @Test("Feature 3 title is not empty")
    func feature3TitleIsNotEmpty() {
        #expect(!Localizable.paywall.feature3Title.isEmpty)
    }

    @Test("Feature 3 description is not empty")
    func feature3DescriptionIsNotEmpty() {
        #expect(!Localizable.paywall.feature3Description.isEmpty)
    }

    // MARK: - Error Handling Tests

    @Test("Error title is not empty")
    func errorTitleIsNotEmpty() {
        #expect(!Localizable.paywall.errorTitle.isEmpty)
    }

    @Test("Retry string is not empty")
    func retryStringIsNotEmpty() {
        #expect(!Localizable.paywall.retry.isEmpty)
    }

    @Test("Restore purchases string is not empty")
    func restorePurchasesStringIsNotEmpty() {
        #expect(!Localizable.paywall.restorePurchases.isEmpty)
    }

    // MARK: - Settings Entry Tests

    @Test("Go premium string is not empty")
    func goPremiumStringIsNotEmpty() {
        #expect(!Localizable.paywall.goPremium.isEmpty)
    }

    @Test("Unlock features string is not empty")
    func unlockFeaturesStringIsNotEmpty() {
        #expect(!Localizable.paywall.unlockFeatures.isEmpty)
    }

    // MARK: - Premium Status Tests

    @Test("Premium active string is not empty")
    func premiumActiveStringIsNotEmpty() {
        #expect(!Localizable.paywall.premiumActive.isEmpty)
    }

    @Test("Full access string is not empty")
    func fullAccessStringIsNotEmpty() {
        #expect(!Localizable.paywall.fullAccess.isEmpty)
    }

    // MARK: - Default Value Tests

    @Test("Loading has expected default value")
    func loadingHasExpectedDefaultValue() {
        #expect(Localizable.paywall.loading == "Loading...")
    }

    @Test("Title has expected default value")
    func titleHasExpectedDefaultValue() {
        #expect(Localizable.paywall.title == "Unlock Premium")
    }

    @Test("Error title has expected default value")
    func errorTitleHasExpectedDefaultValue() {
        #expect(Localizable.paywall.errorTitle == "Error")
    }

    @Test("Retry has expected default value")
    func retryHasExpectedDefaultValue() {
        #expect(Localizable.paywall.retry == "Retry")
    }
}
