import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveSettingsService Tests")
struct LiveSettingsServiceTests {
    @Test("LiveSettingsService can be instantiated")
    func canBeInstantiated() {
        let mockStorage = MockStorageService()
        let service = LiveSettingsService(storageService: mockStorage)
        #expect(service is SettingsService)
    }

    @Test("fetchPreferences returns correct publisher type")
    func fetchPreferencesReturnsCorrectType() {
        let mockStorage = MockStorageService()
        let service = LiveSettingsService(storageService: mockStorage)
        let publisher = service.fetchPreferences()
        let typeCheck: AnyPublisher<UserPreferences, Error> = publisher
        #expect(typeCheck is AnyPublisher<UserPreferences, Error>)
    }

    @Test("savePreferences returns correct publisher type")
    func savePreferencesReturnsCorrectType() {
        let mockStorage = MockStorageService()
        let service = LiveSettingsService(storageService: mockStorage)
        let publisher = service.savePreferences(.default)
        let typeCheck: AnyPublisher<Void, Error> = publisher
        #expect(typeCheck is AnyPublisher<Void, Error>)
    }
}
