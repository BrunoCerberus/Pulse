import Foundation

// MARK: - Analytics Screen

enum AnalyticsScreen: String {
    case home
    case media
    case feed
    case search
    case bookmarks
    case settings
    case articleDetail = "article_detail"
    case mediaDetail = "media_detail"
    case onboarding
}

// MARK: - Analytics Source

enum AnalyticsSource: String {
    case home
    case search
    case bookmarks
    case feed
}

// MARK: - Analytics Event

enum AnalyticsEvent {
    case screenView(screen: AnalyticsScreen)
    case articleOpened(source: AnalyticsSource)
    case articleBookmarked
    case articleUnbookmarked
    case articleShared
    case searchPerformed(queryLength: Int, resultCount: Int)
    case categorySelected(category: String)
    case mediaPlayed(type: String)
    case digestGenerated(success: Bool)
    case articleSummarized(success: Bool)
    case paywallShown(feature: String)
    case purchaseStarted(productId: String)
    case purchaseCompleted(productId: String)
    case purchaseFailed(productId: String, error: String)
    case signIn(provider: String, success: Bool)
    case signOut
    case onboardingCompleted(page: Int)
    case onboardingSkipped(page: Int)

    var name: String {
        switch self {
        case .screenView: "screen_view"
        case .articleOpened: "article_opened"
        case .articleBookmarked: "article_bookmarked"
        case .articleUnbookmarked: "article_unbookmarked"
        case .articleShared: "article_shared"
        case .searchPerformed: "search_performed"
        case .categorySelected: "category_selected"
        case .mediaPlayed: "media_played"
        case .digestGenerated: "digest_generated"
        case .articleSummarized: "article_summarized"
        case .paywallShown: "paywall_shown"
        case .purchaseStarted: "purchase_started"
        case .purchaseCompleted: "purchase_completed"
        case .purchaseFailed: "purchase_failed"
        case .signIn: "sign_in"
        case .signOut: "sign_out"
        case .onboardingCompleted: "onboarding_completed"
        case .onboardingSkipped: "onboarding_skipped"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case let .screenView(screen):
            ["screen_name": screen.rawValue]
        case let .articleOpened(source):
            ["source": source.rawValue]
        case .articleBookmarked, .articleUnbookmarked, .articleShared, .signOut:
            nil
        case let .searchPerformed(queryLength, resultCount):
            ["query_length": queryLength, "result_count": resultCount]
        case let .categorySelected(category):
            ["category": category]
        case let .mediaPlayed(type):
            ["media_type": type]
        case let .digestGenerated(success):
            ["success": success]
        case let .articleSummarized(success):
            ["success": success]
        case let .paywallShown(feature):
            ["feature": feature]
        case let .purchaseStarted(productId):
            ["product_id": productId]
        case let .purchaseCompleted(productId):
            ["product_id": productId]
        case let .purchaseFailed(productId, error):
            ["product_id": productId, "error": error]
        case let .signIn(provider, success):
            ["provider": provider, "success": success]
        case let .onboardingCompleted(page):
            ["page": page]
        case let .onboardingSkipped(page):
            ["page": page]
        }
    }
}

// MARK: - Analytics Service Protocol

protocol AnalyticsService {
    func logEvent(_ event: AnalyticsEvent)
    func setUserProperty(_ value: String?, forName name: String)
    func setUserID(_ userID: String?)
    func recordError(_ error: Error, userInfo: [String: Any]?)
    func log(_ message: String)
}

extension AnalyticsService {
    func recordError(_ error: Error) {
        recordError(error, userInfo: nil)
    }
}
