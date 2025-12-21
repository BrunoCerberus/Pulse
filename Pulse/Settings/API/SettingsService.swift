import Combine
import Foundation

protocol SettingsService {
    func fetchPreferences() -> AnyPublisher<UserPreferences, Error>
    func savePreferences(_ preferences: UserPreferences) -> AnyPublisher<Void, Error>
    func clearReadingHistory() -> AnyPublisher<Void, Error>
}
