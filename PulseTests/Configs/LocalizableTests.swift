// swiftlint:disable file_length
import Foundation
@testable import Pulse
import Testing

// MARK: - Common Strings Tests

@Suite("Common Localization Tests")
struct CommonLocalizableTests {
    @Test("App name is not empty")
    func appNameIsNotEmpty() {
        let value = String(localized: "app.name")
        #expect(!value.isEmpty)
        #expect(value == "Pulse")
    }

    @Test("OK button is not empty")
    func okButtonIsNotEmpty() {
        let value = String(localized: "common.ok")
        #expect(!value.isEmpty)
        #expect(value == "OK")
    }

    @Test("Cancel button is not empty")
    func cancelButtonIsNotEmpty() {
        let value = String(localized: "common.cancel")
        #expect(!value.isEmpty)
        #expect(value == "Cancel")
    }

    @Test("Error title is not empty")
    func errorTitleIsNotEmpty() {
        let value = String(localized: "common.error")
        #expect(!value.isEmpty)
        #expect(value == "Error")
    }

    @Test("Try again button is not empty")
    func tryAgainButtonIsNotEmpty() {
        let value = String(localized: "common.try_again")
        #expect(!value.isEmpty)
        #expect(value == "Try Again")
    }

    @Test("Back button is not empty")
    func backButtonIsNotEmpty() {
        let value = String(localized: "common.back")
        #expect(!value.isEmpty)
        #expect(value == "Back")
    }

    @Test("Loading more text is not empty")
    func loadingMoreIsNotEmpty() {
        let value = String(localized: "common.loading_more")
        #expect(!value.isEmpty)
        #expect(value == "Loading more...")
    }

    @Test("Version label is not empty")
    func versionLabelIsNotEmpty() {
        let value = String(localized: "common.version")
        #expect(!value.isEmpty)
        #expect(value == "Version")
    }
}

// MARK: - Tab Bar Tests

@Suite("Tab Bar Localization Tests")
struct TabBarLocalizableTests {
    @Test("Home tab is not empty")
    func homeTabIsNotEmpty() {
        let value = String(localized: "tab.home")
        #expect(!value.isEmpty)
        #expect(value == "Home")
    }

    @Test("Search tab is not empty")
    func searchTabIsNotEmpty() {
        let value = String(localized: "tab.search")
        #expect(!value.isEmpty)
        #expect(value == "Search")
    }

    @Test("Bookmarks tab is not empty")
    func bookmarksTabIsNotEmpty() {
        let value = String(localized: "tab.bookmarks")
        #expect(!value.isEmpty)
        #expect(value == "Bookmarks")
    }
}

// MARK: - Category Names Tests

@Suite("Category Names Localization Tests")
struct CategoryNamesLocalizableTests {
    @Test("World category is not empty")
    func worldCategoryIsNotEmpty() {
        let value = String(localized: "category.world")
        #expect(!value.isEmpty)
        #expect(value == "World")
    }

    @Test("Business category is not empty")
    func businessCategoryIsNotEmpty() {
        let value = String(localized: "category.business")
        #expect(!value.isEmpty)
        #expect(value == "Business")
    }

    @Test("Technology category is not empty")
    func technologyCategoryIsNotEmpty() {
        let value = String(localized: "category.technology")
        #expect(!value.isEmpty)
        #expect(value == "Technology")
    }

    @Test("Science category is not empty")
    func scienceCategoryIsNotEmpty() {
        let value = String(localized: "category.science")
        #expect(!value.isEmpty)
        #expect(value == "Science")
    }

    @Test("Health category is not empty")
    func healthCategoryIsNotEmpty() {
        let value = String(localized: "category.health")
        #expect(!value.isEmpty)
        #expect(value == "Health")
    }

    @Test("Sports category is not empty")
    func sportsCategoryIsNotEmpty() {
        let value = String(localized: "category.sports")
        #expect(!value.isEmpty)
        #expect(value == "Sports")
    }

    @Test("Entertainment category is not empty")
    func entertainmentCategoryIsNotEmpty() {
        let value = String(localized: "category.entertainment")
        #expect(!value.isEmpty)
        #expect(value == "Entertainment")
    }
}

// MARK: - Home Screen Tests

@Suite("Home Screen Localization Tests")
struct HomeLocalizableTests {
    @Test("Home title is not empty")
    func homeTitleIsNotEmpty() {
        let value = String(localized: "home.title")
        #expect(!value.isEmpty)
        #expect(value == "News")
    }

    @Test("Breaking news label is not empty")
    func breakingNewsLabelIsNotEmpty() {
        let value = String(localized: "home.breaking")
        #expect(!value.isEmpty)
        #expect(value == "BREAKING")
    }

    @Test("Home error title is not empty")
    func homeErrorTitleIsNotEmpty() {
        let value = String(localized: "home.error.title")
        #expect(!value.isEmpty)
        #expect(value == "Unable to Load News")
    }

    @Test("Home empty title is not empty")
    func homeEmptyTitleIsNotEmpty() {
        let value = String(localized: "home.empty.title")
        #expect(!value.isEmpty)
        #expect(value == "No News Available")
    }

    @Test("Home empty message is not empty")
    func homeEmptyMessageIsNotEmpty() {
        let value = String(localized: "home.empty.message")
        #expect(!value.isEmpty)
    }
}

// MARK: - Search Screen Tests

@Suite("Search Screen Localization Tests")
struct SearchLocalizableTests {
    @Test("Search title is not empty")
    func searchTitleIsNotEmpty() {
        let value = String(localized: "search.title")
        #expect(!value.isEmpty)
        #expect(value == "Search")
    }

    @Test("Searching text is not empty")
    func searchingTextIsNotEmpty() {
        let value = String(localized: "search.searching")
        #expect(!value.isEmpty)
        #expect(value == "Searching...")
    }

    @Test("Search placeholder title is not empty")
    func searchPlaceholderTitleIsNotEmpty() {
        let value = String(localized: "search.placeholder.title")
        #expect(!value.isEmpty)
        #expect(value == "Search for News")
    }

    @Test("Search placeholder message is not empty")
    func searchPlaceholderMessageIsNotEmpty() {
        let value = String(localized: "search.placeholder.message")
        #expect(!value.isEmpty)
    }

    @Test("Search error title is not empty")
    func searchErrorTitleIsNotEmpty() {
        let value = String(localized: "search.error.title")
        #expect(!value.isEmpty)
        #expect(value == "Search Failed")
    }

    @Test("Search empty title is not empty")
    func searchEmptyTitleIsNotEmpty() {
        let value = String(localized: "search.empty.title")
        #expect(!value.isEmpty)
        #expect(value == "No Results Found")
    }
}

// MARK: - Bookmarks Screen Tests

@Suite("Bookmarks Screen Localization Tests")
struct BookmarksLocalizableTests {
    @Test("Bookmarks title is not empty")
    func bookmarksTitleIsNotEmpty() {
        let value = String(localized: "bookmarks.title")
        #expect(!value.isEmpty)
        #expect(value == "Bookmarks")
    }

    @Test("Bookmarks loading is not empty")
    func bookmarksLoadingIsNotEmpty() {
        let value = String(localized: "bookmarks.loading")
        #expect(!value.isEmpty)
        #expect(value == "Loading bookmarks...")
    }

    @Test("Bookmarks error title is not empty")
    func bookmarksErrorTitleIsNotEmpty() {
        let value = String(localized: "bookmarks.error.title")
        #expect(!value.isEmpty)
    }

    @Test("Bookmarks empty title is not empty")
    func bookmarksEmptyTitleIsNotEmpty() {
        let value = String(localized: "bookmarks.empty.title")
        #expect(!value.isEmpty)
        #expect(value == "No Bookmarks")
    }

    @Test("Bookmarks empty message is not empty")
    func bookmarksEmptyMessageIsNotEmpty() {
        let value = String(localized: "bookmarks.empty.message")
        #expect(!value.isEmpty)
    }
}

// MARK: - Article Screen Tests

@Suite("Article Screen Localization Tests")
struct ArticleLocalizableTests {
    @Test("Read full article button is not empty")
    func readFullArticleButtonIsNotEmpty() {
        let value = String(localized: "article.read_full")
        #expect(!value.isEmpty)
        #expect(value == "Read Full Article")
    }

    @Test("Bookmark button is not empty")
    func bookmarkButtonIsNotEmpty() {
        let value = String(localized: "article.bookmark")
        #expect(!value.isEmpty)
        #expect(value == "Bookmark")
    }

    @Test("Share button is not empty")
    func shareButtonIsNotEmpty() {
        let value = String(localized: "article.share")
        #expect(!value.isEmpty)
        #expect(value == "Share")
    }
}

// MARK: - Settings Screen Tests

@Suite("Settings Screen Localization Tests")
struct SettingsLocalizableTests {
    @Test("Settings title is not empty")
    func settingsTitleIsNotEmpty() {
        let value = String(localized: "settings.title")
        #expect(!value.isEmpty)
        #expect(value == "Settings")
    }

    @Test("Followed topics title is not empty")
    func followedTopicsTitleIsNotEmpty() {
        let value = String(localized: "settings.followed_topics")
        #expect(!value.isEmpty)
        #expect(value == "Followed Topics")
    }

    @Test("Followed topics description is not empty")
    func followedTopicsDescriptionIsNotEmpty() {
        let value = String(localized: "settings.followed_topics.description")
        #expect(!value.isEmpty)
    }

    @Test("Clear history button is not empty")
    func clearHistoryButtonIsNotEmpty() {
        let value = String(localized: "settings.clear_history")
        #expect(!value.isEmpty)
        #expect(value == "Clear Reading History")
    }

    @Test("Clear history confirm is not empty")
    func clearHistoryConfirmIsNotEmpty() {
        let value = String(localized: "settings.clear_history.confirm")
        #expect(!value.isEmpty)
    }

    @Test("Clear history action is not empty")
    func clearHistoryActionIsNotEmpty() {
        let value = String(localized: "settings.clear_history.action")
        #expect(!value.isEmpty)
        #expect(value == "Clear")
    }

    @Test("View on GitHub is not empty")
    func viewOnGitHubIsNotEmpty() {
        let value = String(localized: "settings.view_github")
        #expect(!value.isEmpty)
        #expect(value == "View on GitHub")
    }
}

// MARK: - Account Tests

@Suite("Account Localization Tests")
struct AccountLocalizableTests {
    @Test("Account title is not empty")
    func accountTitleIsNotEmpty() {
        let value = String(localized: "account.title")
        #expect(!value.isEmpty)
        #expect(value == "Account")
    }

    @Test("Sign out button is not empty")
    func signOutButtonIsNotEmpty() {
        let value = String(localized: "account.sign_out")
        #expect(!value.isEmpty)
        #expect(value == "Sign Out")
    }

    @Test("Sign out confirm is not empty")
    func signOutConfirmIsNotEmpty() {
        let value = String(localized: "account.sign_out.confirm")
        #expect(!value.isEmpty)
    }
}

// MARK: - Auth Screen Tests

@Suite("Auth Screen Localization Tests")
struct AuthLocalizableTests {
    @Test("Auth tagline is not empty")
    func authTaglineIsNotEmpty() {
        let value = String(localized: "auth.tagline")
        #expect(!value.isEmpty)
        #expect(value == "Your personalized news experience")
    }

    @Test("Sign in with Apple button is not empty")
    func signInWithAppleButtonIsNotEmpty() {
        let value = String(localized: "auth.sign_in_apple")
        #expect(!value.isEmpty)
        #expect(value == "Sign in with Apple")
    }

    @Test("Sign in with Google button is not empty")
    func signInWithGoogleButtonIsNotEmpty() {
        let value = String(localized: "auth.sign_in_google")
        #expect(!value.isEmpty)
        #expect(value == "Sign in with Google")
    }

    @Test("Terms text is not empty")
    func termsTextIsNotEmpty() {
        let value = String(localized: "auth.terms")
        #expect(!value.isEmpty)
    }

    @Test("Signing in text is not empty")
    func signingInTextIsNotEmpty() {
        let value = String(localized: "auth.signing_in")
        #expect(!value.isEmpty)
        #expect(value == "Signing in...")
    }
}

// MARK: - Paywall Tests

@Suite("Paywall Localization Tests")
struct PaywallLocalizableTests {
    @Test("Loading string is not empty")
    func loadingStringIsNotEmpty() {
        #expect(!Localizable.paywall.loading.isEmpty)
        #expect(Localizable.paywall.loading == "Loading...")
    }

    @Test("Title string is not empty")
    func titleStringIsNotEmpty() {
        #expect(!Localizable.paywall.title.isEmpty)
        #expect(Localizable.paywall.title == "Unlock Premium")
    }

    @Test("Subtitle string is not empty")
    func subtitleStringIsNotEmpty() {
        #expect(!Localizable.paywall.subtitle.isEmpty)
    }

    @Test("Feature 1 title is not empty")
    func feature1TitleIsNotEmpty() {
        #expect(!Localizable.paywall.feature1Title.isEmpty)
        #expect(Localizable.paywall.feature1Title == "Unlimited Articles")
    }

    @Test("Feature 1 description is not empty")
    func feature1DescriptionIsNotEmpty() {
        #expect(!Localizable.paywall.feature1Description.isEmpty)
    }

    @Test("Feature 2 title is not empty")
    func feature2TitleIsNotEmpty() {
        #expect(!Localizable.paywall.feature2Title.isEmpty)
        #expect(Localizable.paywall.feature2Title == "Offline Reading")
    }

    @Test("Feature 2 description is not empty")
    func feature2DescriptionIsNotEmpty() {
        #expect(!Localizable.paywall.feature2Description.isEmpty)
    }

    @Test("Feature 3 title is not empty")
    func feature3TitleIsNotEmpty() {
        #expect(!Localizable.paywall.feature3Title.isEmpty)
        #expect(Localizable.paywall.feature3Title == "Ad-Free Experience")
    }

    @Test("Feature 3 description is not empty")
    func feature3DescriptionIsNotEmpty() {
        #expect(!Localizable.paywall.feature3Description.isEmpty)
    }

    @Test("Error title is not empty")
    func errorTitleIsNotEmpty() {
        #expect(!Localizable.paywall.errorTitle.isEmpty)
        #expect(Localizable.paywall.errorTitle == "Error")
    }

    @Test("Retry string is not empty")
    func retryStringIsNotEmpty() {
        #expect(!Localizable.paywall.retry.isEmpty)
        #expect(Localizable.paywall.retry == "Retry")
    }

    @Test("Restore purchases string is not empty")
    func restorePurchasesStringIsNotEmpty() {
        #expect(!Localizable.paywall.restorePurchases.isEmpty)
        #expect(Localizable.paywall.restorePurchases == "Restore Purchases")
    }

    @Test("Go premium string is not empty")
    func goPremiumStringIsNotEmpty() {
        #expect(!Localizable.paywall.goPremium.isEmpty)
        #expect(Localizable.paywall.goPremium == "Go Premium")
    }

    @Test("Unlock features string is not empty")
    func unlockFeaturesStringIsNotEmpty() {
        #expect(!Localizable.paywall.unlockFeatures.isEmpty)
    }

    @Test("Premium active string is not empty")
    func premiumActiveStringIsNotEmpty() {
        #expect(!Localizable.paywall.premiumActive.isEmpty)
        #expect(Localizable.paywall.premiumActive == "Premium Active")
    }

    @Test("Full access string is not empty")
    func fullAccessStringIsNotEmpty() {
        #expect(!Localizable.paywall.fullAccess.isEmpty)
    }
}

// MARK: - All Keys Existence Tests

@Suite("Localization Keys Existence Tests")
struct LocalizationKeysExistenceTests {
    /// All localization keys that should exist in Localizable.strings
    private static let allKeys: [String] = [
        // Common
        "app.name",
        "common.ok",
        "common.cancel",
        "common.error",
        "common.try_again",
        "common.back",
        "common.loading_more",
        "common.version",
        "common.share",
        // Tab Bar
        "tab.home",
        "tab.for_you",
        "tab.search",
        "tab.bookmarks",
        // Categories
        "category.world",
        "category.business",
        "category.technology",
        "category.science",
        "category.health",
        "category.sports",
        "category.entertainment",
        // Home
        "home.title",
        "home.breaking",
        "home.breaking_news",
        "home.top_headlines",
        "home.category.all",
        "home.error.title",
        "home.empty.title",
        "home.empty.message",
        "home.offline.title",
        "home.offline.message",
        // For You
        "for_you.title",
        "for_you.error.title",
        "for_you.empty.title",
        "for_you.empty.message",
        "for_you.set_preferences",
        "for_you.no_articles.title",
        "for_you.no_articles.message",
        // Search
        "search.title",
        "search.searching",
        "search.placeholder.title",
        "search.placeholder.message",
        "search.error.title",
        "search.empty.title",
        // Bookmarks
        "bookmarks.title",
        "bookmarks.loading",
        "bookmarks.error.title",
        "bookmarks.empty.title",
        "bookmarks.empty.message",
        // Article
        "article.read_full",
        "article.bookmark",
        "article.share",
        "article.by_author",
        // Settings
        "settings.title",
        "settings.followed_topics",
        "settings.followed_topics.description",
        "settings.clear_history",
        "settings.clear_history.confirm",
        "settings.clear_history.action",
        "settings.view_github",
        // Account
        "account.title",
        "account.sign_out",
        "account.sign_out.confirm",
        // Auth
        "auth.tagline",
        "auth.sign_in_apple",
        "auth.sign_in_google",
        "auth.terms",
        "auth.signing_in",
        // Paywall
        "paywall.loading",
        "paywall.title",
        "paywall.subtitle",
        "paywall.feature1.title",
        "paywall.feature1.description",
        "paywall.feature2.title",
        "paywall.feature2.description",
        "paywall.feature3.title",
        "paywall.feature3.description",
        "paywall.error.title",
        "paywall.retry",
        "paywall.restore_purchases",
        "paywall.go_premium",
        "paywall.unlock_features",
        "paywall.premium_active",
        "paywall.full_access",
        // Search
        "search.prompt",
        "search.recent_searches",
        "search.trending_topics",
        "search.offline.title",
        "search.offline.message",
        // Media
        "media.title",
        "media.featured",
        "media.latest",
        "media.all_types",
        "media.error.title",
        "media.empty.title",
        "media.empty.message",
        "media.offline.title",
        "media.offline.message",
        "media.unsupported_type",
        // Settings - Notifications
        "settings.notifications",
        "settings.enable_notifications",
        "settings.breaking_news_alerts",
        // Settings - Appearance
        "settings.appearance",
        "settings.use_system_theme",
        "settings.dark_mode",
        // Settings - About
        "settings.about",
        // Settings - Muted Content
        "settings.muted_sources",
        "settings.muted_sources.add",
        "settings.muted_keywords",
        "settings.muted_keywords.add",
        "settings.muted_sources.add_action",
        "settings.muted_sources.remove_action",
        "settings.muted_keywords.add_action",
        "settings.muted_keywords.remove_action",
        // Settings - Content Language
        "settings.content_language",
        "settings.content_language.label",
        "settings.content_language.description",
        // Language
        "language.english",
        "language.portuguese",
        "language.spanish",
        // Account - Accessibility
        "account.profile_photo",
        "account.user_initial",
        // Feed
        "feed.title",
        "feed.header_title",
        "feed.empty.title",
        "feed.empty.message",
        "feed.error.title",
        "feed.offline.title",
        "feed.offline.message",
        "feed.start_reading",
        "feed.no_articles.title",
        "feed.no_articles.message",
        "feed.no_articles.retry",
        "feed.ai_processing.status",
        "feed.ai_digest",
        // Media - YouTube
        "media.watch_on_youtube",
        "media.watch_on_youtube.accessibility",
        // Offline
        "offline.banner",
    ]

    @Test("All localization keys exist and are not empty", arguments: allKeys)
    func keyExistsAndIsNotEmpty(key: String) {
        let value = String(localized: String.LocalizationValue(key))
        #expect(!value.isEmpty, "Key '\(key)' should have a non-empty value")
        // Check that value is not the same as the key (which would indicate missing translation)
        #expect(value != key, "Key '\(key)' appears to be missing a translation")
    }
}
