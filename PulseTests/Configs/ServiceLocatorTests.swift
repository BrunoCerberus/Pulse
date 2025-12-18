import Testing
import Foundation
@testable import Pulse

@Suite("ServiceLocator Tests")
struct ServiceLocatorTests {
    @Test("Register and retrieve service")
    func testRegisterAndRetrieve() throws {
        let serviceLocator = ServiceLocator()
        let mockService = MockNewsService()
        serviceLocator.register(NewsService.self, instance: mockService)

        let resolved = try serviceLocator.retrieve(NewsService.self)
        #expect(resolved is MockNewsService)
    }

    @Test("Retrieve throws for unregistered service")
    func testRetrieveThrows() {
        let serviceLocator = ServiceLocator()

        #expect(throws: ServiceLocatorError.self) {
            _ = try serviceLocator.retrieve(NewsService.self)
        }
    }

    @Test("Safe retrieve returns nil for unregistered service")
    func testSafeRetrieve() {
        let serviceLocator = ServiceLocator()

        let resolved = serviceLocator.safeRetrieve(NewsService.self)
        #expect(resolved == nil)
    }

    @Test("Clear removes all services")
    func testClear() throws {
        let serviceLocator = ServiceLocator()
        let mockService = MockNewsService()
        serviceLocator.register(NewsService.self, instance: mockService)
        serviceLocator.clear()

        // Wait for async clear to complete
        Thread.sleep(forTimeInterval: 0.1)

        let resolved = serviceLocator.safeRetrieve(NewsService.self)
        #expect(resolved == nil)
    }

    @Test("Register overwrites existing service")
    func testOverwrite() throws {
        let serviceLocator = ServiceLocator()
        let firstService = MockNewsService()
        let secondService = MockNewsService()

        serviceLocator.register(NewsService.self, instance: firstService)
        serviceLocator.register(NewsService.self, instance: secondService)

        // Wait for async registration to complete
        Thread.sleep(forTimeInterval: 0.1)

        let resolved = try serviceLocator.retrieve(NewsService.self) as? MockNewsService
        #expect(resolved === secondService)
    }

    @Test("Is registered returns correct value")
    func testIsRegistered() {
        let serviceLocator = ServiceLocator()
        let mockService = MockNewsService()

        #expect(!serviceLocator.isRegistered(NewsService.self))

        serviceLocator.register(NewsService.self, instance: mockService)

        // Wait for async registration to complete
        Thread.sleep(forTimeInterval: 0.1)

        #expect(serviceLocator.isRegistered(NewsService.self))
    }

    @Test("Factory registration creates new instances")
    func testFactoryRegistration() throws {
        let serviceLocator = ServiceLocator()
        var callCount = 0

        serviceLocator.register(NewsService.self, factory: {
            callCount += 1
            return MockNewsService()
        })

        // Wait for async registration to complete
        Thread.sleep(forTimeInterval: 0.1)

        _ = try serviceLocator.retrieve(NewsService.self)
        _ = try serviceLocator.retrieve(NewsService.self)

        #expect(callCount == 2)
    }
}
