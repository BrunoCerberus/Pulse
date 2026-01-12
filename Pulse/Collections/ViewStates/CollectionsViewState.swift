import Foundation

struct CollectionsViewState: Equatable {
    var featuredCollections: [CollectionViewItem]
    var userCollections: [CollectionViewItem]
    var isLoading: Bool
    var isRefreshing: Bool
    var errorMessage: String?
    var showEmptyState: Bool
    var showEmptyUserCollections: Bool
    var selectedCollection: Collection?
    var showCreateSheet: Bool
    var collectionToDelete: Collection?

    static var initial: CollectionsViewState {
        CollectionsViewState(
            featuredCollections: [],
            userCollections: [],
            isLoading: false,
            isRefreshing: false,
            errorMessage: nil,
            showEmptyState: false,
            showEmptyUserCollections: true,
            selectedCollection: nil,
            showCreateSheet: false,
            collectionToDelete: nil
        )
    }
}

struct CollectionViewItem: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let articleCount: Int
    let readCount: Int
    let progress: Double
    let isPremium: Bool
    let collectionType: CollectionType

    var progressText: String {
        "\(readCount)/\(articleCount) articles"
    }

    var isCompleted: Bool {
        articleCount > 0 && readCount >= articleCount
    }

    init(from collection: Collection) {
        id = collection.id
        name = collection.name
        description = collection.description
        iconName = Self.iconName(for: collection)
        articleCount = collection.articleCount
        readCount = collection.readArticleIDs.count
        progress = collection.progress
        isPremium = collection.isPremium
        collectionType = collection.collectionType
    }

    private static func iconName(for collection: Collection) -> String {
        if let definition = CollectionDefinition.all.first(where: { $0.id == collection.id }) {
            return definition.iconName
        }

        switch collection.collectionType {
        case .featured:
            return "star.fill"
        case .topic:
            return "newspaper.fill"
        case .user:
            return "folder.fill"
        case .aiCurated:
            return "sparkles"
        }
    }
}
