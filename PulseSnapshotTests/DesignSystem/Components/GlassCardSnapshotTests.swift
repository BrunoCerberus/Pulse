import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class GlassCardSnapshotTests: XCTestCase {
    // MARK: - GlassCard Tests

    func testGlassCardRegularStyle() {
        let view = GlassCard(style: .regular) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Glass Card")
                    .font(Typography.titleMedium)
                Text("This is a glassmorphism styled card with blur effect.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testGlassCardUltraThinStyle() {
        let view = GlassCard(style: .ultraThin, shadowStyle: .subtle) {
            Text("Ultra Thin Style")
                .font(Typography.bodyMedium)
        }
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    func testGlassCardThinStyle() {
        let view = GlassCard(style: .thin, shadowStyle: .elevated, showBorder: false) {
            Text("Thin Style - No Border")
                .font(Typography.bodyMedium)
        }
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - GlassCardButton Tests

    func testGlassCardButton() {
        let view = GlassCardButton(action: {}) {
            HStack {
                Image(systemName: "star.fill")
                Text("Tap Me")
                    .font(Typography.labelLarge)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }

    // MARK: - GlassContainer Tests

    func testGlassContainer() {
        let view = GlassContainer(style: .thin) {
            HStack {
                Text("Container Content")
                    .font(Typography.bodyMedium)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 393)
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision)),
            record: false
        )
    }
}
