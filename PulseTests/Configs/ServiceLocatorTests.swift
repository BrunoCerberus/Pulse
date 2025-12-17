import Testing
@testable import Pulse

@Suite("ServiceLocator Tests")
struct ServiceLocatorTests {
    @Test("Register and resolve service")
    func testRegisterAndResolve() {
        let mockService = MockNewsService()
        ServiceLocator.shared.register(NewsService.self, service: mockService)

        let resolved = ServiceLocator.shared.resolve(NewsService.self)
        #expect(resolved is MockNewsService)
    }

    @Test("Resolve optional returns nil for unregistered service")
    func testResolveOptional() {
        ServiceLocator.shared.reset()

        let resolved = ServiceLocator.shared.resolveOptional(NewsService.self)
        #expect(resolved == nil)
    }

    @Test("Reset clears all services")
    func testReset() {
        let mockService = MockNewsService()
        ServiceLocator.shared.register(NewsService.self, service: mockService)
        ServiceLocator.shared.reset()

        let resolved = ServiceLocator.shared.resolveOptional(NewsService.self)
        #expect(resolved == nil)
    }

    @Test("Register overwrites existing service")
    func testOverwrite() {
        let firstService = MockNewsService()
        let secondService = MockNewsService()

        ServiceLocator.shared.register(NewsService.self, service: firstService)
        ServiceLocator.shared.register(NewsService.self, service: secondService)

        let resolved = ServiceLocator.shared.resolve(NewsService.self) as? MockNewsService
        #expect(resolved === secondService)
    }
}
