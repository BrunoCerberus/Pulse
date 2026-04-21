import Foundation
@testable import Pulse
import Testing

private typealias Constants = SettingsView.Constants

@Suite("SettingsView Constants Tests")
@MainActor
struct SettingsConstantsTests {
    init() async {
        AppLocalization.shared.updateLanguage("en")
    }

    @Test("legal section header is not empty")
    func legalSectionHeaderIsNotEmpty() {
        #expect(!Constants.legal.isEmpty)
    }

    @Test("privacyPolicy label is not empty")
    func privacyPolicyLabelIsNotEmpty() {
        #expect(!Constants.privacyPolicy.isEmpty)
    }

    @Test("termsOfService label is not empty")
    func termsOfServiceLabelIsNotEmpty() {
        #expect(!Constants.termsOfService.isEmpty)
    }
}
