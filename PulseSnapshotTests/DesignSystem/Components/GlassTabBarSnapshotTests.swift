@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class GlassTabBarSnapshotTests: XCTestCase {
    // Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // MARK: - Tab Selection Tests

    func testGlassTabBarHomeSelected() {
        let view = TabBarTestWrapper(selectedTab: .home)
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassTabBarForYouSelected() {
        let view = TabBarTestWrapper(selectedTab: .forYou)
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassTabBarCategoriesSelected() {
        let view = TabBarTestWrapper(selectedTab: .categories)
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassTabBarBookmarksSelected() {
        let view = TabBarTestWrapper(selectedTab: .bookmarks)
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassTabBarSearchSelected() {
        let view = TabBarTestWrapper(selectedTab: .search)
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Full Screen with Tab Bar

    func testGlassTabBarInContext() {
        let view = ZStack {
            LinearGradient.meshFallback
                .ignoresSafeArea()

            VStack {
                Text("Content Area")
                    .font(.title)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.top, 100)
        }
        .glassTabBar(selectedTab: .constant(.home))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}

// MARK: - Test Helper

private struct TabBarTestWrapper: View {
    @State var selectedTab: AppTab

    init(selectedTab: AppTab) {
        _selectedTab = State(initialValue: selectedTab)
    }

    var body: some View {
        VStack {
            Spacer()
            GlassTabBar(selectedTab: $selectedTab)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
