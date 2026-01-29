import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class GlassCategoryChipSnapshotTests: XCTestCase {
    /// Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // MARK: - GlassCategoryChip Size Tests

    func testGlassCategoryChipSmall() {
        let view = HStack(spacing: 8) {
            GlassCategoryChip(category: .technology, style: .small)
            GlassCategoryChip(category: .business, style: .small)
            GlassCategoryChip(category: .science, style: .small)
        }
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassCategoryChipMedium() {
        let view = HStack(spacing: 8) {
            GlassCategoryChip(category: .technology, style: .medium)
            GlassCategoryChip(category: .business, style: .medium)
            GlassCategoryChip(category: .science, style: .medium)
        }
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassCategoryChipLarge() {
        let view = HStack(spacing: 8) {
            GlassCategoryChip(category: .technology, style: .large)
            GlassCategoryChip(category: .business, style: .large)
            GlassCategoryChip(category: .science, style: .large)
        }
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - GlassCategoryChip Selection State Tests

    func testGlassCategoryChipSelected() {
        let view = HStack(spacing: 8) {
            GlassCategoryChip(category: .technology, style: .medium, isSelected: true)
            GlassCategoryChip(category: .technology, style: .medium, isSelected: false)
        }
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassCategoryChipWithIcon() {
        let view = HStack(spacing: 8) {
            GlassCategoryChip(category: .technology, style: .medium, showIcon: true)
            GlassCategoryChip(category: .health, style: .medium, showIcon: true)
            GlassCategoryChip(category: .sports, style: .medium, showIcon: true)
        }
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassCategoryChipSelectedWithIcon() {
        let view = HStack(spacing: 8) {
            GlassCategoryChip(category: .technology, style: .large, isSelected: true, showIcon: true)
            GlassCategoryChip(category: .health, style: .large, isSelected: false, showIcon: true)
        }
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - All Categories Test

    func testGlassCategoryChipAllCategories() {
        let view = VStack(spacing: 8) {
            ForEach(NewsCategory.allCases, id: \.self) { category in
                HStack(spacing: 8) {
                    GlassCategoryChip(category: category, style: .medium, isSelected: false, showIcon: true)
                    GlassCategoryChip(category: category, style: .medium, isSelected: true, showIcon: true)
                }
            }
        }
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - GlassCategoryButton Tests

    func testGlassCategoryButtonUnselected() {
        let view = HStack(spacing: 8) {
            GlassCategoryButton(category: .technology, isSelected: false) {}
            GlassCategoryButton(category: .business, isSelected: false) {}
            GlassCategoryButton(category: .science, isSelected: false) {}
        }
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassCategoryButtonSelected() {
        let view = HStack(spacing: 8) {
            GlassCategoryButton(category: .technology, isSelected: true) {}
            GlassCategoryButton(category: .technology, isSelected: false) {}
        }
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassCategoryButtonAllCategories() {
        let view = ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    GlassCategoryButton(
                        category: category,
                        isSelected: category == .technology
                    ) {}
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 140)
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - GlassTopicChip Tests

    func testGlassTopicChipUnselected() {
        let view = HStack(spacing: 8) {
            GlassTopicChip(topic: "AI", isSelected: false, color: .purple) {}
            GlassTopicChip(topic: "Startups", isSelected: false, color: .blue) {}
            GlassTopicChip(topic: "Gaming", isSelected: false, color: .green) {}
        }
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassTopicChipSelected() {
        let view = HStack(spacing: 8) {
            GlassTopicChip(topic: "AI", isSelected: true, color: .purple) {}
            GlassTopicChip(topic: "Startups", isSelected: true, color: .blue) {}
            GlassTopicChip(topic: "Gaming", isSelected: true, color: .green) {}
        }
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassTopicChipMixed() {
        let view = HStack(spacing: 8) {
            GlassTopicChip(topic: "AI", isSelected: true, color: .purple) {}
            GlassTopicChip(topic: "Startups", isSelected: false, color: .blue) {}
            GlassTopicChip(topic: "Gaming", isSelected: false, color: .green) {}
        }
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}
