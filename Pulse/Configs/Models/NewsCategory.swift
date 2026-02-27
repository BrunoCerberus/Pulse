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
        case .world: return AppLocalization.localized("category.world")
        case .business: return AppLocalization.localized("category.business")
        case .technology: return AppLocalization.localized("category.technology")
        case .science: return AppLocalization.localized("category.science")
        case .health: return AppLocalization.localized("category.health")
        case .sports: return AppLocalization.localized("category.sports")
        case .entertainment: return AppLocalization.localized("category.entertainment")
        }
    }

    var icon: String {
        switch self {
        case .world: return "globe"
        case .business: return "chart.line.uptrend.xyaxis"
        case .technology: return "cpu"
        case .science: return "atom"
        case .health: return "heart.text.square"
        case .sports: return "sportscourt"
        case .entertainment: return "film"
        }
    }

    var apiParameter: String {
        switch self {
        case .world: return "general"
        case .business: return "business"
        case .technology: return "technology"
        case .science: return "science"
        case .health: return "health"
        case .sports: return "sports"
        case .entertainment: return "entertainment"
        }
    }

    var guardianSection: String {
        switch self {
        case .world: return "world"
        case .business: return "business"
        case .technology: return "technology"
        case .science: return "science"
        case .health: return "society"
        case .sports: return "sport"
        case .entertainment: return "culture"
        }
    }

    static func fromGuardianSection(_ section: String) -> NewsCategory {
        switch section.lowercased() {
        case "world", "uk-news", "us-news", "australia-news":
            return .world
        case "business", "money":
            return .business
        case "technology":
            return .technology
        case "science":
            return .science
        case "society", "healthcare-network":
            return .health
        case "sport", "football":
            return .sports
        case "culture", "film", "music", "books", "tv-and-radio", "stage":
            return .entertainment
        default:
            // Default to world for unmapped sections (e.g., environment, politics, etc.)
            return .world
        }
    }
}
