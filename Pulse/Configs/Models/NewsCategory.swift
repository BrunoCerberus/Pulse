import Foundation

enum NewsCategory: String, CaseIterable, Codable, Identifiable {
    case world
    case business
    case technology
    case science
    case health
    case sports
    case entertainment

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .world: AppLocalization.localized("category.world")
        case .business: AppLocalization.localized("category.business")
        case .technology: AppLocalization.localized("category.technology")
        case .science: AppLocalization.localized("category.science")
        case .health: AppLocalization.localized("category.health")
        case .sports: AppLocalization.localized("category.sports")
        case .entertainment: AppLocalization.localized("category.entertainment")
        }
    }

    var icon: String {
        switch self {
        case .world: "globe"
        case .business: "chart.line.uptrend.xyaxis"
        case .technology: "cpu"
        case .science: "atom"
        case .health: "heart.text.square"
        case .sports: "sportscourt"
        case .entertainment: "film"
        }
    }

    var apiParameter: String {
        switch self {
        case .world: "general"
        case .business: "business"
        case .technology: "technology"
        case .science: "science"
        case .health: "health"
        case .sports: "sports"
        case .entertainment: "entertainment"
        }
    }
}
