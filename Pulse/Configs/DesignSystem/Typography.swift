import SwiftUI

// MARK: - Typography

enum Typography {
    // MARK: - Display (Large headers with rounded design)

    static let displayLarge = Font.system(.largeTitle, design: .rounded)
    static let displayMedium = Font.system(.title, design: .rounded)
    static let displaySmall = Font.system(.title2, design: .rounded)

    // MARK: - Title (Section headers)

    static let titleLarge = Font.system(.title2)
    static let titleMedium = Font.system(.title3)
    static let titleSmall = Font.system(.headline)

    // MARK: - Headline (Article titles, emphasis)

    static let headlineLarge = Font.system(.headline)
    static let headlineMedium = Font.system(.headline)
    static let headlineSmall = Font.system(.subheadline)

    // MARK: - Body (Content text)

    static let bodyLarge = Font.system(.body)
    static let bodyMedium = Font.system(.body)
    static let bodySmall = Font.system(.callout)

    // MARK: - Caption (Supporting text)

    static let captionLarge = Font.system(.caption)
    static let captionMedium = Font.system(.caption2)
    static let captionSmall = Font.system(.caption2)

    // MARK: - Label (Buttons, badges)

    static let labelLarge = Font.system(.subheadline)
    static let labelMedium = Font.system(.caption)
    static let labelSmall = Font.system(.caption2)
}

// MARK: - Text Style Modifiers

extension View {
    func displayLarge() -> some View {
        font(Typography.displayLarge)
    }

    func displayMedium() -> some View {
        font(Typography.displayMedium)
    }

    func displaySmall() -> some View {
        font(Typography.displaySmall)
    }

    func titleLarge() -> some View {
        font(Typography.titleLarge)
    }

    func titleMedium() -> some View {
        font(Typography.titleMedium)
    }

    func titleSmall() -> some View {
        font(Typography.titleSmall)
    }

    func headlineLarge() -> some View {
        font(Typography.headlineLarge)
    }

    func headlineMedium() -> some View {
        font(Typography.headlineMedium)
    }

    func headlineSmall() -> some View {
        font(Typography.headlineSmall)
    }

    func bodyLarge() -> some View {
        font(Typography.bodyLarge)
    }

    func bodyMedium() -> some View {
        font(Typography.bodyMedium)
    }

    func bodySmall() -> some View {
        font(Typography.bodySmall)
    }

    func captionLarge() -> some View {
        font(Typography.captionLarge)
    }

    func captionMedium() -> some View {
        font(Typography.captionMedium)
    }

    func captionSmall() -> some View {
        font(Typography.captionSmall)
    }

    func labelLarge() -> some View {
        font(Typography.labelLarge)
    }

    func labelMedium() -> some View {
        font(Typography.labelMedium)
    }

    func labelSmall() -> some View {
        font(Typography.labelSmall)
    }
}
