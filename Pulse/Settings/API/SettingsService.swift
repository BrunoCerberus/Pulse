import Combine
import Foundation

protocol SettingsService {
    func fetchPreferences() -> AnyPublisher<UserPreferences, Error>
    func savePreferences(_ preferences: UserPreferences) -> AnyPublisher<Void, Error>
    func clearReadingHistory() -> AnyPublisher<Void, Error>
}

final class LiveSettingsService: SettingsService {
    private let storageService: StorageService

    init(storageService: StorageService) {
        self.storageService = storageService
    }

    func fetchPreferences() -> AnyPublisher<UserPreferences, Error> {
        Future { [storageService] promise in
            Task {
                do {
                    let preferences = try await storageService.fetchUserPreferences() ?? .default
                    promise(.success(preferences))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func savePreferences(_ preferences: UserPreferences) -> AnyPublisher<Void, Error> {
        Future { [storageService] promise in
            Task {
                do {
                    try await storageService.saveUserPreferences(preferences)
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func clearReadingHistory() -> AnyPublisher<Void, Error> {
        Future { [storageService] promise in
            Task {
                do {
                    try await storageService.clearReadingHistory()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
