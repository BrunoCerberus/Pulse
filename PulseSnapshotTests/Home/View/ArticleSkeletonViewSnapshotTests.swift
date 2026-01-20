@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class ArticleSkeletonViewSnapshotTests: XCTestCase {
    // MARK: - Standard Skeleton Tests

    func testArticleSkeletonStandardState() {
        let view = ArticleSkeletonView()
            .frame(width: 375, height: 120)
            .padding()
            .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Multiple Skeleton Rows (Loading State Simulation)

    func testArticleSkeletonMultipleRows() {
        let view = VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                ArticleSkeletonView()
                    .frame(height: 100)
            }
        }
        .padding()
        .frame(width: 375)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Dark Mode Tests

    func testArticleSkeletonDarkMode() {
        let view = ArticleSkeletonView()
            .frame(width: 375, height: 120)
            .padding()
            .background(Color(.systemBackground))
            .preferredColorScheme(.dark)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testArticleSkeletonLightMode() {
        let view = ArticleSkeletonView()
            .frame(width: 375, height: 120)
            .padding()
            .background(Color(.systemBackground))
            .preferredColorScheme(.light)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - Full Screen Loading Simulation

    func testArticleSkeletonFullScreenLoading() {
        let view = VStack(alignment: .leading, spacing: 16) {
            // Breaking news skeleton
            ArticleSkeletonView()
                .frame(height: 200)

            // Headlines skeletons
            VStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    ArticleSkeletonView()
                        .frame(height: 100)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}
