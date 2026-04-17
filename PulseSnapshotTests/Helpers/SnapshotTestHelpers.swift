import SnapshotTesting
import UIKit

/// Shared snapshot testing configuration for consistent test setup across all snapshot tests.
enum SnapshotConfig {
    /// Standard iPhone Air configuration matching CI environment (dark mode, 0.99 precision).
    static let iPhoneAir = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    )

    /// iPhone Air configuration in light mode.
    static let iPhoneAirLight = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(userInterfaceStyle: .light)
    )

    /// iPad configuration for tablet testing (landscape, 1024x768).
    @MainActor static let iPad: ViewImageConfig = {
        let traits = UITraitCollection { mutableTraits in
            mutableTraits.userInterfaceStyle = .dark
            mutableTraits.horizontalSizeClass = .regular
            mutableTraits.verticalSizeClass = .regular
            mutableTraits.userInterfaceIdiom = .pad
        }
        return ViewImageConfig(
            safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
            size: CGSize(width: 1024, height: 768),
            traits: traits
        )
    }()

    /// iPad Pro 13" portrait configuration — validates adaptive layouts on the
    /// widest canvas (grids, split view detail column, capped reading width).
    @MainActor static let iPadPro13: ViewImageConfig = {
        let traits = UITraitCollection { mutableTraits in
            mutableTraits.userInterfaceStyle = .dark
            mutableTraits.horizontalSizeClass = .regular
            mutableTraits.verticalSizeClass = .regular
            mutableTraits.userInterfaceIdiom = .pad
        }
        return ViewImageConfig(
            safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
            size: CGSize(width: 1032, height: 1376),
            traits: traits
        )
    }()

    /// iPhone Air with accessibility extra-large content size category (dark mode).
    @MainActor static let iPhoneAirAccessibility: ViewImageConfig = {
        let traits = UITraitCollection { mutableTraits in
            mutableTraits.userInterfaceStyle = .dark
            mutableTraits.preferredContentSizeCategory = .accessibilityExtraLarge
        }
        return ViewImageConfig(
            safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
            size: CGSize(width: 393, height: 852),
            traits: traits
        )
    }()

    /// iPhone Air with extra-extra-large content size category (dark mode).
    @MainActor static let iPhoneAirExtraExtraLarge: ViewImageConfig = {
        let traits = UITraitCollection { mutableTraits in
            mutableTraits.userInterfaceStyle = .dark
            mutableTraits.preferredContentSizeCategory = .extraExtraLarge
        }
        return ViewImageConfig(
            safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
            size: CGSize(width: 393, height: 852),
            traits: traits
        )
    }()

    /// Standard precision for snapshot comparisons (99%).
    static let standardPrecision: Float = 0.99

    /// Standard snapshotting strategy with a 1-second wait for view rendering.
    static func snapshotting(
        on config: ViewImageConfig,
        precision: Float = standardPrecision
    ) -> Snapshotting<UIViewController, UIImage> {
        .wait(for: 1.0, on: .image(on: config, precision: precision))
    }
}
