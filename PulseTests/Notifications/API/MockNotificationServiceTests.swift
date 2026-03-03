import Foundation
@testable import Pulse
import Testing

@Suite("MockNotificationService Tests")
@MainActor
struct MockNotificationServiceTests {
    @Test("Authorization status returns configured value")
    func authorizationStatusUsesConfiguredResult() async {
        let sut = MockNotificationService()
        sut.authorizationStatusResult = .provisional

        let status = await sut.authorizationStatus()

        #expect(status == .provisional)
    }

    @Test("Request authorization increments call count and returns result")
    func requestAuthorizationTracksCalls() async throws {
        let sut = MockNotificationService()
        sut.requestAuthorizationResult = .success(false)

        let granted = try await sut.requestAuthorization()

        #expect(granted == false)
        #expect(sut.requestAuthorizationCallCount == 1)
    }

    @Test("Request authorization propagates configured error")
    func requestAuthorizationPropagatesError() async {
        enum ExpectedError: Error, Equatable {
            case denied
        }

        let sut = MockNotificationService()
        sut.requestAuthorizationResult = .failure(ExpectedError.denied)

        await #expect(throws: ExpectedError.denied) {
            try await sut.requestAuthorization()
        }
        #expect(sut.requestAuthorizationCallCount == 1)
    }

    @Test("Register and unregister track call counts")
    func registerAndUnregisterTrackCalls() async {
        let sut = MockNotificationService()

        await sut.registerForRemoteNotifications()
        await sut.registerForRemoteNotifications()
        await sut.unregisterForRemoteNotifications()

        #expect(sut.registerCallCount == 2)
        #expect(sut.unregisterCallCount == 1)
    }

    @Test("Store device token encodes lowercase hex")
    func storeDeviceTokenStoresHexString() {
        let sut = MockNotificationService()
        let token = Data([0xAB, 0x10, 0x2F, 0x00])

        sut.storeDeviceToken(token)

        #expect(sut.storedDeviceToken == "ab102f00")
    }
}
