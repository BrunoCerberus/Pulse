import SwiftUI

// MARK: - Typography

enum Typography {
    // MARK: - Display (Large headers with rounded design)

    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 24, weight: .semibold, design: .rounded)

    // MARK: - Title (Section headers)

    static let titleLarge = Font.system(size: 22, weight: .semibold)
    static let titleMedium = Font.system(size: 18, weight: .semibold)
    static let titleSmall = Font.system(size: 16, weight: .semibold)

    // MARK: - Headline (Article titles, emphasis)

    static let headlineLarge = Font.system(size: 17, weight: .semibold)
    static let headlineMedium = Font.system(size: 15, weight: .semibold)
    static let headlineSmall = Font.system(size: 14, weight: .semibold)

    // MARK: - Body (Content text)

    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)

    // MARK: - Caption (Supporting text)

    static let captionLarge = Font.system(size: 12, weight: .medium)
    static let captionMedium = Font.system(size: 11, weight: .medium)
    static let captionSmall = Font.system(size: 10, weight: .regular)

    // MARK: - Label (Buttons, badges)

    static let labelLarge = Font.system(size: 14, weight: .semibold)
    static let labelMedium = Font.system(size: 12, weight: .semibold)
    static let labelSmall = Font.system(size: 10, weight: .bold)
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
