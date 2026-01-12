import Foundation

struct CollectionDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let query: String?
    let section: String?
    let articleCount: Int
    let isPremium: Bool
    let collectionType: CollectionType
    let orderBy: String

    static let featured: [CollectionDefinition] = [
        CollectionDefinition(
            id: "climate-crisis",
            name: "Climate Crisis",
            description: "Understand the science, politics, and solutions to our planet's greatest challenge",
            iconName: "leaf.fill",
            query: "climate change",
            section: "environment",
            articleCount: 10,
            isPremium: false,
            collectionType: .featured,
            orderBy: "relevance"
        ),
        CollectionDefinition(
            id: "ai-technology",
            name: "AI & Technology",
            description: "The latest developments in artificial intelligence and how they're shaping our world",
            iconName: "brain.head.profile",
            query: "artificial intelligence",
            section: "technology",
            articleCount: 10,
            isPremium: false,
            collectionType: .featured,
            orderBy: "newest"
        ),
        CollectionDefinition(
            id: "world-politics",
            name: "Global Politics",
            description: "Key political events and analysis from around the world",
            iconName: "globe.europe.africa.fill",
            query: nil,
            section: "politics",
            articleCount: 12,
            isPremium: false,
            collectionType: .featured,
            orderBy: "newest"
        ),
        CollectionDefinition(
            id: "business-finance",
            name: "Business & Markets",
            description: "Economic trends, market analysis, and business insights",
            iconName: "chart.line.uptrend.xyaxis",
            query: nil,
            section: "business",
            articleCount: 10,
            isPremium: true,
            collectionType: .featured,
            orderBy: "newest"
        ),
        CollectionDefinition(
            id: "science-discovery",
            name: "Science & Discovery",
            description: "Breakthrough research and scientific discoveries explained",
            iconName: "atom",
            query: nil,
            section: "science",
            articleCount: 10,
            isPremium: false,
            collectionType: .featured,
            orderBy: "newest"
        ),
        CollectionDefinition(
            id: "culture-arts",
            name: "Culture & Arts",
            description: "Reviews, features, and commentary on arts and culture",
            iconName: "theatermasks.fill",
            query: nil,
            section: "culture",
            articleCount: 8,
            isPremium: true,
            collectionType: .featured,
            orderBy: "newest"
        ),
    ]

    static let topics: [CollectionDefinition] = [
        CollectionDefinition(
            id: "weekly-tech",
            name: "This Week in Tech",
            description: "The week's most important technology stories",
            iconName: "laptopcomputer",
            query: nil,
            section: "technology",
            articleCount: 15,
            isPremium: false,
            collectionType: .topic,
            orderBy: "newest"
        ),
        CollectionDefinition(
            id: "health-wellness",
            name: "Health & Wellness",
            description: "Latest health news, medical research, and wellness tips",
            iconName: "heart.fill",
            query: nil,
            section: "lifeandstyle",
            articleCount: 10,
            isPremium: false,
            collectionType: .topic,
            orderBy: "newest"
        ),
        CollectionDefinition(
            id: "sports-highlights",
            name: "Sports Highlights",
            description: "Top stories from the world of sports",
            iconName: "sportscourt.fill",
            query: nil,
            section: "sport",
            articleCount: 12,
            isPremium: false,
            collectionType: .topic,
            orderBy: "newest"
        ),
    ]

    static var all: [CollectionDefinition] {
        featured + topics
    }
}
