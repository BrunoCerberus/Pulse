@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class CachedAsyncImageSnapshotTests: XCTestCase {
    /// Custom device config matching CI's iPhone Air simulator (forced dark mode)
    private let iPhoneAirConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    /// Light mode config for additional coverage
    private let iPhoneAirLightConfig = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .light)
    )

    // MARK: - Loading State Tests

    func testCachedAsyncImageLoading() {
        let view = CachedAsyncImage(
            url: URL(string: "https://example.com/image.jpg"),
            accessibilityLabel: "Test image"
        ) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ProgressView()
        }
        .frame(width: 200, height: 200)
        .clipped()

        let controller = UIHostingController(rootView: view)

        // Short wait to capture loading state
        assertSnapshot(
            of: controller,
            as: .wait(for: 0.1, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testCachedAsyncImageLoadingLightMode() {
        let view = CachedAsyncImage(
            url: URL(string: "https://example.com/image.jpg"),
            accessibilityLabel: "Test image"
        ) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ProgressView()
        }
        .frame(width: 200, height: 200)
        .clipped()

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.1, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Placeholder Tests

    func testCachedAsyncImageWithPlaceholder() {
        let view = CachedAsyncImage(
            url: URL(string: "https://example.com/slow-loading-image.jpg"),
            accessibilityLabel: "Placeholder test"
        ) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                Color.gray.opacity(0.2)
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.1, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Nil URL Tests

    func testCachedAsyncImageNilURL() {
        let view = CachedAsyncImage(
            url: nil,
            accessibilityLabel: "Nil URL test"
        ) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                Color.gray.opacity(0.3)
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))

        let controller = UIHostingController(rootView: view)

        // With nil URL, placeholder should be shown indefinitely
        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    func testCachedAsyncImageNilURLLightMode() {
        let view = CachedAsyncImage(
            url: nil,
            accessibilityLabel: "Nil URL light mode test"
        ) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                Color.gray.opacity(0.3)
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 1.0, on: .image(on: iPhoneAirLightConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Convenience Initializer Tests

    func testCachedAsyncImageConvenienceInit() {
        // Test the convenience initializer that uses ProgressView as default placeholder
        let view = CachedAsyncImage(
            url: URL(string: "https://example.com/image.jpg"),
            accessibilityLabel: "Convenience init test"
        ) { image in
            image
                .resizable()
                .scaledToFit()
        }
        .frame(width: 150, height: 150)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.1, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }

    // MARK: - Article Card Context Tests

    func testCachedAsyncImageInArticleCardContext() {
        // Test the image in a realistic card context
        let view = VStack(spacing: 12) {
            CachedAsyncImage(
                url: URL(string: "https://example.com/article-image.jpg"),
                accessibilityLabel: "Article thumbnail"
            ) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        ProgressView()
                    }
            }
            .frame(width: 350, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text("Article Title Goes Here")
                    .font(.headline)
                    .lineLimit(2)

                Text("Brief description of the article content")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(width: 375)
        .background(Color(.systemBackground))

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: .wait(for: 0.1, on: .image(on: iPhoneAirConfig, precision: 0.99)),
            record: false
        )
    }
}
