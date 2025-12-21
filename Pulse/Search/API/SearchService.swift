import Combine
import Foundation

protocol SearchService {
    func search(query: String, page: Int, sortBy: String) -> AnyPublisher<[Article], Error>
    func getSuggestions(for query: String) -> AnyPublisher<[String], Never>
}
