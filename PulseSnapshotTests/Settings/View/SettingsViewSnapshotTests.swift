import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SettingsViewSnapshotTests: XCTestCase {
    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        // Set authenticated state before SettingsViewModel is created
        AuthenticationManager.shared.setAuthenticatedForTesting(.mock)

        // Create a window for proper view lifecycle
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window?.isHidden = true
        window = nil
        AuthenticationManager.shared.setUnauthenticatedForTesting()
        super.tearDown()
    }

    func testSettingsViewInitial() {
        // Use preview ServiceLocator which has all mocks configured
        let serviceLocator = ServiceLocator.preview

        // Create view with NavigationStack
        let view = NavigationStack {
            SettingsView(serviceLocator: serviceLocator)
        }
        let controller = UIHostingController(rootView: view)

        // Add to window to trigger full view lifecycle
        window.rootViewController = controller
        controller.view.layoutIfNeeded()

        // Wait for Combine pipeline and SwiftUI to settle
        let expectation = XCTestExpectation(description: "Wait for view to settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        assertSnapshot(
            of: controller,
            as: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision),
            record: false
        )
    }

    // MARK: - SettingsAccountSection Tests

    func testSettingsAccountSectionWithUser() {
        let user = AuthUser.mock
        let view = Form {
            SettingsAccountSection(
                currentUser: user,
                onSignOutTapped: {}
            )
        }
        .frame(width: 393, height: 300)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testSettingsAccountSectionWithoutUser() {
        let view = Form {
            SettingsAccountSection(
                currentUser: nil,
                onSignOutTapped: {}
            )
        }
        .frame(width: 393, height: 200)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - SettingsMutedContentSection Tests

    func testSettingsMutedContentSectionEmpty() {
        struct TestWrapper: View {
            @State var newSource = ""
            @State var newKeyword = ""

            var body: some View {
                Form {
                    SettingsMutedContentSection(
                        mutedSources: [],
                        mutedKeywords: [],
                        newMutedSource: $newSource,
                        newMutedKeyword: $newKeyword,
                        onAddMutedSource: {},
                        onRemoveMutedSource: { _ in },
                        onAddMutedKeyword: {},
                        onRemoveMutedKeyword: { _ in }
                    )
                }
            }
        }

        let view = TestWrapper()
            .frame(width: 393, height: 300)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testSettingsMutedContentSectionWithItems() {
        struct TestWrapper: View {
            @State var newSource = ""
            @State var newKeyword = ""

            var body: some View {
                Form {
                    SettingsMutedContentSection(
                        mutedSources: ["CNN", "Fox News"],
                        mutedKeywords: ["politics", "celebrity"],
                        newMutedSource: $newSource,
                        newMutedKeyword: $newKeyword,
                        onAddMutedSource: {},
                        onRemoveMutedSource: { _ in },
                        onAddMutedKeyword: {},
                        onRemoveMutedKeyword: { _ in }
                    )
                }
            }
        }

        let view = TestWrapper()
            .frame(width: 393, height: 400)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - SettingsPremiumSection Tests

    func testSettingsPremiumSectionNotPremium() {
        let view = Form {
            SettingsPremiumSection(
                isPremium: false,
                onUpgradeTapped: {}
            )
        }
        .frame(width: 393, height: 200)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testSettingsPremiumSectionPremium() {
        let view = Form {
            SettingsPremiumSection(
                isPremium: true,
                onUpgradeTapped: {}
            )
        }
        .frame(width: 393, height: 200)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}
