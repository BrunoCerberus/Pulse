import SwiftUI

enum OnboardingPage: Int, CaseIterable, Equatable, Identifiable {
    case welcome
    case aiPowered
    case stayConnected
    case getStarted

    var id: Int {
        rawValue
    }

    var icon: String {
        switch self {
        case .welcome: "newspaper.fill"
        case .aiPowered: "sparkles"
        case .stayConnected: "bookmark.fill"
        case .getStarted: "arrow.right.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .welcome: .purple
        case .aiPowered: .blue
        case .stayConnected: .orange
        case .getStarted: .green
        }
    }

    var title: String {
        switch self {
        case .welcome: String(localized: "onboarding.welcome.title")
        case .aiPowered: String(localized: "onboarding.ai_powered.title")
        case .stayConnected: String(localized: "onboarding.stay_connected.title")
        case .getStarted: String(localized: "onboarding.get_started.title")
        }
    }

    var subtitle: String {
        switch self {
        case .welcome: String(localized: "onboarding.welcome.subtitle")
        case .aiPowered: String(localized: "onboarding.ai_powered.subtitle")
        case .stayConnected: String(localized: "onboarding.stay_connected.subtitle")
        case .getStarted: String(localized: "onboarding.get_started.subtitle")
        }
    }
}
