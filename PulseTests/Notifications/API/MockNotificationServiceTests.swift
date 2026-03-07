import Foundation
@testable import Pulse
import Testing

@Suite("MockNotificationService Tests")
@MainActor
struct MockNotificationServiceTests {
    // MARK: - Authorization Status

    @Test("Returns configured authorization status")
    func authorizationStatus() async {
        let service = MockNotificationService()
        service.authorizationStatusResult = .authorized
        let status = await service.authorizationStatus()
        #expect(status == .authorized)
    }

    @Test("Returns notDetermined by default")
    func defaultAuthorizationStatus() async {
        let service = MockNotificationService()
        let status = await service.authorizationStatus()
        #expect(status == .notDetermined)
    }

    @Test("Returns denied status")
    func deniedAuthorizationStatus() async {
        let service = MockNotificationService()
        service.authorizationStatusResult = .denied
        let status = await service.authorizationStatus()
        #expect(status == .denied)
    }

    @Test("Returns provisional status")
    func provisionalAuthorizationStatus() async {
        let service = MockNotificationService()
        service.authorizationStatusResult = .provisional
        let status = await service.authorizationStatus()
        #expect(status == .provisional)
    }

    // MARK: - Request Authorization

    @Test("Request authorization increments call count")
    func requestAuthorizationCallCount() async throws {
        let service = MockNotificationService()
        _ = try await service.requestAuthorization()
        _ = try await service.requestAuthorization()
        #expect(service.requestAuthorizationCallCount == 2)
    }

    @Test("Request authorization returns configured result")
    func requestAuthorizationResult() async throws {
        let service = MockNotificationService()
        service.requestAuthorizationResult = .success(false)
        let granted = try await service.requestAuthorization()
        #expect(granted == false)
    }

    @Test("Request authorization throws configured error")
    func requestAuthorizationThrows() async {
        let service = MockNotificationService()
        service.requestAuthorizationResult = .failure(URLError(.notConnectedToInternet))

        do {
            _ = try await service.requestAuthorization()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is URLError)
        }
    }

    // MARK: - Register / Unregister

    @Test("Register increments call count")
    func registerCallCount() async {
        let service = MockNotificationService()
        await service.registerForRemoteNotifications()
        await service.registerForRemoteNotifications()
        #expect(service.registerCallCount == 2)
    }

    @Test("Unregister increments call count")
    func unregisterCallCount() async {
        let service = MockNotificationService()
        await service.unregisterForRemoteNotifications()
        #expect(service.unregisterCallCount == 1)
    }

    // MARK: - Device Token Storage

    @Test("Stores device token as hex string")
    func storeDeviceToken() {
        let service = MockNotificationService()
        let tokenBytes: [UInt8] = [0xDE, 0xAD, 0xBE, 0xEF, 0x01, 0x23, 0x45, 0x67]
        let tokenData = Data(tokenBytes)
        service.storeDeviceToken(tokenData)
        #expect(service.storedDeviceToken == "deadbeef01234567")
    }

    @Test("Device token is nil by default")
    func defaultDeviceToken() {
        let service = MockNotificationService()
        #expect(service.storedDeviceToken == nil)
    }

    @Test("Stores empty token as empty string")
    func emptyDeviceToken() {
        let service = MockNotificationService()
        service.storeDeviceToken(Data())
        #expect(service.storedDeviceToken == "")
    }
}
