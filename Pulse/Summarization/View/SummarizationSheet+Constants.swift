import SwiftUI

// MARK: - Constants

enum SummarizationConstants {
    static var title: String {
        AppLocalization.localized("summarization.title")
    }

    static var subtitle: String {
        AppLocalization.localized("summarization.subtitle")
    }

    static var generateButton: String {
        AppLocalization.localized("summarization.generate")
    }

    static var cancelButton: String {
        AppLocalization.localized("summarization.cancel")
    }

    static var retryButton: String {
        AppLocalization.localized("summarization.retry")
    }

    static var loadingModel: String {
        AppLocalization.localized("summarization.loading_model")
    }

    static var generating: String {
        AppLocalization.localized("summarization.generating")
    }

    static var aiSummary: String {
        AppLocalization.localized("summarization.ai_summary")
    }

    static var summarizationComplete: String {
        AppLocalization.localized("accessibility.summarization_complete")
    }
}

// MARK: - Animation Constants

enum SummarizationAnimationConstants {
    static let stateTransition: Animation = .spring(response: 0.5, dampingFraction: 0.8)
    static let contentAppear: Animation = .easeOut(duration: 0.4)
    static let shimmerDuration: Double = 1.5
    static let iconGlowRadius: CGFloat = 20
    static let typingDotSize: CGFloat = 6
    static let typingDotSpacing: CGFloat = 4
    static let bulletPointSize: CGFloat = 6
    static let bulletPointTopPadding: CGFloat = 7
}
