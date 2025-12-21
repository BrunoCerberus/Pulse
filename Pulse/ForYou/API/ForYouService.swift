import Combine
import Foundation

protocol ForYouService {
    func fetchPersonalizedFeed(preferences: UserPreferences, page: Int) -> AnyPublisher<[Article], Error>
}
