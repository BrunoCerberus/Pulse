//
//  Localizable.swift
//  Pulse
//
//  Created by bruno on localization.
//

import Foundation

/// Localizable wrapper providing easy access to localized strings.
///
/// This struct provides a centralized way to access localized strings throughout the app.
/// It uses NSLocalizedString internally and provides type-safe access to all localized content.
///
/// Example usage:
/// ```swift
/// Text(Localizable.paywall.title)
/// ```
struct Localizable {
    // MARK: - Private Initializer

    /// Private initializer to prevent instantiation
    private init() {}

    // MARK: - Paywall

    /// Paywall related localized strings
    struct Paywall {
        /// Private initializer to prevent instantiation
        private init() {}

        /// "Loading..." loading state message
        static let loading = NSLocalizedString("paywall.loading", value: "Loading...", comment: "Loading paywall message")

        /// "Unlock Premium" title
        static let title = NSLocalizedString("paywall.title", value: "Unlock Premium", comment: "Paywall title")

        /// Subtitle describing premium benefits
        static let subtitle = NSLocalizedString(
            "paywall.subtitle",
            value: "Get the full Pulse experience with unlimited access",
            comment: "Paywall subtitle"
        )

        /// First feature title
        static let feature1Title = NSLocalizedString(
            "paywall.feature1.title",
            value: "Unlimited Articles",
            comment: "Feature 1 title"
        )

        /// First feature description
        static let feature1Description = NSLocalizedString(
            "paywall.feature1.description",
            value: "Read as many articles as you want without limits",
            comment: "Feature 1 description"
        )

        /// Second feature title
        static let feature2Title = NSLocalizedString(
            "paywall.feature2.title",
            value: "Offline Reading",
            comment: "Feature 2 title"
        )

        /// Second feature description
        static let feature2Description = NSLocalizedString(
            "paywall.feature2.description",
            value: "Save unlimited articles for offline access",
            comment: "Feature 2 description"
        )

        /// Third feature title
        static let feature3Title = NSLocalizedString(
            "paywall.feature3.title",
            value: "Ad-Free Experience",
            comment: "Feature 3 title"
        )

        /// Third feature description
        static let feature3Description = NSLocalizedString(
            "paywall.feature3.description",
            value: "Enjoy a clean, distraction-free reading experience",
            comment: "Feature 3 description"
        )

        /// "Error" title for error state
        static let errorTitle = NSLocalizedString("paywall.error.title", value: "Error", comment: "Paywall error title")

        /// "Retry" button text
        static let retry = NSLocalizedString("paywall.retry", value: "Retry", comment: "Retry button text")

        /// "Restore Purchases" button text
        static let restorePurchases = NSLocalizedString(
            "paywall.restore_purchases",
            value: "Restore Purchases",
            comment: "Restore purchases button"
        )

        /// "Go Premium" settings entry point title
        static let goPremium = NSLocalizedString("paywall.go_premium", value: "Go Premium", comment: "Go premium button")

        /// "Unlock all features" settings entry point description
        static let unlockFeatures = NSLocalizedString(
            "paywall.unlock_features",
            value: "Unlock all premium features",
            comment: "Unlock features description"
        )

        /// "Premium Active" status for subscribed users
        static let premiumActive = NSLocalizedString(
            "paywall.premium_active",
            value: "Premium Active",
            comment: "Premium active status"
        )

        /// "You have full access" description for subscribed users
        static let fullAccess = NSLocalizedString(
            "paywall.full_access",
            value: "You have full access to all features",
            comment: "Full access description"
        )
    }

    // MARK: - Convenience Access

    /// Convenience access to paywall strings
    static let paywall = Paywall.self
}
