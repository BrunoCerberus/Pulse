@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class StretchyHeaderSnapshotTests: XCTestCase {
    // MARK: - StretchyHeader Tests

    func testStretchyHeaderWithGradient() {
        let view = ScrollView {
            VStack(spacing: 0) {
                StretchyHeader(baseHeight: 280) {
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                Text("Content Below")
                    .font(Typography.titleMedium)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial)
            }
        }
        .frame(width: 393, height: 500)
        .ignoresSafeArea(.container, edges: .top)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testStretchyHeaderWithoutOverlay() {
        let view = ScrollView {
            VStack(spacing: 0) {
                StretchyHeader(
                    baseHeight: 200,
                    showGradientOverlay: false
                ) {
                    Color.orange
                }

                Text("No Overlay")
                    .font(Typography.bodyMedium)
                    .padding()
            }
        }
        .frame(width: 393, height: 400)
        .ignoresSafeArea(.container, edges: .top)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testStretchyHeaderCustomHeight() {
        let view = ScrollView {
            VStack(spacing: 0) {
                StretchyHeader(
                    baseHeight: 150,
                    gradientHeight: 60
                ) {
                    LinearGradient(
                        colors: [.green, .teal],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

                Text("Compact Header")
                    .font(Typography.bodyMedium)
                    .padding()
            }
        }
        .frame(width: 393, height: 300)
        .ignoresSafeArea(.container, edges: .top)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - StretchyAsyncImage Tests

    func testStretchyAsyncImagePlaceholder() {
        // Test with nil URL to show placeholder
        let view = ScrollView {
            VStack(spacing: 0) {
                StretchyAsyncImage(
                    url: nil,
                    baseHeight: 280
                )

                Text("Article Content")
                    .font(Typography.titleLarge)
                    .padding(Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial)
            }
        }
        .frame(width: 393, height: 500)
        .ignoresSafeArea(.container, edges: .top)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}
