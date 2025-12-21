import Combine
import EntropyCore
import Foundation

final class LiveCategoriesService: APIRequest, CategoriesService {
    func fetchArticles(for category: NewsCategory, page: Int) -> AnyPublisher<[Article], Error> {
        fetchRequest(
            target: GuardianAPI.search(
                query: nil,
                section: category.guardianSection,
                page: page,
                pageSize: 20,
                orderBy: "newest"
            ),
            dataType: GuardianResponse.self
        )
        .map { response in
            response.response.results.compactMap { $0.toArticle(category: category) }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
