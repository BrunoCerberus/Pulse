@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SettingsAccountSectionSnapshotTests: XCTestCase {
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    private var mockAuthUser: AuthUser {
        AuthUser(
            uid: "test-uid-123",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: URL(string: "https://picsum.photos/200"),
            provider: .google
        )
    }

    private var authUserWithInitialOnly: AuthUser {
        AuthUser(
            uid: "test-uid-456",
            email: "initial@example.com",
            displayName: nil,
            photoURL: nil,
            provider: .apple
        )
    }

    private var authUserWithLongName: AuthUser {
        AuthUser(
            uid: "test-uid-789",
            email: "longname@example.com",
            displayName: "This Is A Very Long Display Name That Should Test Truncation",
            photoURL: URL(string: "https://picsum.photos/200"),
            provider: .google
        )
    }

    func testSettingsAccountSectionSignedIn() {
        let view = SettingsAccountSection(
            currentUser: mockAuthUser,
            onSignOutTapped: {}
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }

    func testSettingsAccountSectionInitialOnly() {
        let view = SettingsAccountSection(
            currentUser: authUserWithInitialOnly,
            onSignOutTapped: {}
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }

    func testSettingsAccountSectionLongDisplayName() {
        let view = SettingsAccountSection(
            currentUser: authUserWithLongName,
            onSignOutTapped: {}
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }

    func testSettingsAccountSectionNotSignedIn() {
        let view = SettingsAccountSection(
            currentUser: nil,
            onSignOutTapped: {}
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: iPhoneAirConfig)))
    }
}
