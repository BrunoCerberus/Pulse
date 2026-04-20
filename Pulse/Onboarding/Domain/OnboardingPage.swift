import SwiftUI

enum OnboardingPage: Int, CaseIterable, Equatable, Identifiable {
    case welcome
    case aiPowered
    case stayConnected
    case chooseTopics
    case getStarted

    var id: Int {
        rawValue
    }

    var icon: String {
        switch self {
        case .welcome: "newspaper.fill"
        case .aiPowered: "sparkles"
        case .stayConnected: "bookmark.fill"
        case .chooseTopics: "tag.fill"
        case .getStarted: "arrow.right.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .welcome: .purple
        case .aiPowered: .blue
        case .stayConnected: .orange
        case .chooseTopics: .pink
        case .getStarted: .green
        }
    }

    var title: String {
        switch self {
        case .welcome: AppLocalization.localized("onboarding.welcome.title")
        case .aiPowered: AppLocalization.localized("onboarding.ai_powered.title")
        case .stayConnected: AppLocalization.localized("onboarding.stay_connected.title")
        case .chooseTopics: AppLocalization.localized("onboarding.choose_topics.title")
        case .getStarted: AppLocalization.localized("onboarding.get_started.title")
        }
    }

    var subtitle: String {
        switch self {
        case .welcome: AppLocalization.localized("onboarding.welcome.subtitle")
        case .aiPowered: AppLocalization.localized("onboarding.ai_powered.subtitle")
        case .stayConnected: AppLocalization.localized("onboarding.stay_connected.subtitle")
        case .chooseTopics: AppLocalization.localized("onboarding.choose_topics.subtitle")
        case .getStarted: AppLocalization.localized("onboarding.get_started.subtitle")
        }
    }
}
