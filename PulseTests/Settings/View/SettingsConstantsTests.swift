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

    @Test("deleteAccountTitle label is not empty")
    func deleteAccountTitleIsNotEmpty() {
        #expect(!Constants.deleteAccountTitle.isEmpty)
    }

    @Test("deleteAccountMessage label is not empty")
    func deleteAccountMessageIsNotEmpty() {
        #expect(!Constants.deleteAccountMessage.isEmpty)
    }

    @Test("deleteAccountConfirm label is not empty")
    func deleteAccountConfirmIsNotEmpty() {
        #expect(!Constants.deleteAccountConfirm.isEmpty)
    }
}
