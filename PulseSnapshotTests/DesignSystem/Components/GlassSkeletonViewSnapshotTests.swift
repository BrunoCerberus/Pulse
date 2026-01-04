@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class GlassSkeletonViewSnapshotTests: XCTestCase {
    // Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    // MARK: - SkeletonShape Tests

    func testSkeletonShapeVariations() {
        let view = VStack(spacing: 16) {
            SkeletonShape(width: 100, height: 16, cornerRadius: 4)
            SkeletonShape(width: 200, height: 20, cornerRadius: 8)
            SkeletonShape(height: 14) // Full width
            SkeletonShape(width: 60, height: 60, cornerRadius: 12) // Square
        }
        .padding()
        .frame(width: 350)
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - GlassArticleSkeleton Tests

    func testGlassArticleSkeleton() {
        let view = GlassArticleSkeleton()
            .frame(width: 375)
            .padding()
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassArticleSkeletonMultiple() {
        let view = VStack(spacing: 12) {
            GlassArticleSkeleton()
            GlassArticleSkeleton()
            GlassArticleSkeleton()
        }
        .frame(width: 375)
        .padding()
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - GlassHeroSkeleton Tests

    func testGlassHeroSkeleton() {
        let view = GlassHeroSkeleton()
            .frame(height: 200)
            .padding()
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - GlassCategorySkeleton Tests

    func testGlassCategorySkeleton() {
        let view = GlassCategorySkeleton()
            .padding()
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testGlassCategorySkeletonRow() {
        let view = HStack(spacing: 12) {
            GlassCategorySkeleton()
            GlassCategorySkeleton()
            GlassCategorySkeleton()
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

    // MARK: - ArticleListSkeleton Tests

    func testArticleListSkeletonDefault() {
        let view = ScrollView {
            ArticleListSkeleton()
        }
        .frame(width: 393, height: 600)
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testArticleListSkeletonCustomCount() {
        let view = ScrollView {
            ArticleListSkeleton(count: 3)
        }
        .frame(width: 393, height: 500)
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - HeroCarouselSkeleton Tests

    func testHeroCarouselSkeleton() {
        let view = HeroCarouselSkeleton()
            .frame(height: 220)
            .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Full Loading Page Layout Test

    func testFullLoadingPageLayout() {
        let view = ScrollView {
            VStack(spacing: 24) {
                GlassSectionHeader("Breaking News")

                HeroCarouselSkeleton()
                    .frame(height: 200)

                GlassSectionHeader("Top Stories")

                ArticleListSkeleton(count: 4)
            }
        }
        .background(LinearGradient.meshFallback)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.5, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}
