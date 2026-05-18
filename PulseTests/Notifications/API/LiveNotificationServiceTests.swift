import Foundation
@testable import Pulse
import Testing

/// In-memory `KeychainStore` mirroring the one in `LiveAppLockServiceTests`.
/// Duplicated here to avoid coupling test targets across feature boundaries.
private final class InMemoryKeychainStore: KeychainStore {
    private var store = [String: String]()
    var savedKeys: [String] {
        Array(store.keys)
    }

    func exists(for key: String) -> Bool {
        store[key] != nil
    }

    func save(_ value: String, for key: String) throws {
        store[key] = value
    }

    func retrieve(for key: String) throws -> String {
        guard let value = store[key] else {
            throw NSError(domain: "InMemoryKeychainStore", code: -1)
        }
        return value
    }

    func delete(for key: String) throws {
        store.removeValue(forKey: key)
    }
}

/// Keychain that always throws on `save` — used to exercise the warning
/// path in `LiveNotificationService.storeDeviceToken`.
private final class FailingKeychainStore: KeychainStore {
    func exists(for _: String) -> Bool {
        false
    }

    func save(_: String, for _: String) throws {
        throw NSError(domain: "FailingKeychainStore", code: -1)
    }

    func retrieve(for _: String) throws -> String {
        throw NSError(domain: "FailingKeychainStore", code: -1)
    }

    func delete(for _: String) throws {
        throw NSError(domain: "FailingKeychainStore", code: -1)
    }
}

@Suite("LiveNotificationService Tests", .serialized)
@MainActor
struct LiveNotificationServiceTests {
    private let suiteName = "com.pulse.notifications.tests"

    private func freshDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("storeDeviceToken writes the hex-encoded token to keychain")
    func storeDeviceTokenWritesToKeychain() {
        let keychain = InMemoryKeychainStore()
        let defaults = freshDefaults()
        let service = LiveNotificationService(keychain: keychain, defaults: defaults)

        let tokenBytes: [UInt8] = [0xDE, 0xAD, 0xBE, 0xEF]
        service.storeDeviceToken(Data(tokenBytes))

        #expect(service.storedDeviceToken == "deadbeef")
    }

    @Test("storedDeviceToken returns nil when nothing has been stored")
    func storedDeviceTokenNilWhenEmpty() {
        let keychain = InMemoryKeychainStore()
        let defaults = freshDefaults()
        let service = LiveNotificationService(keychain: keychain, defaults: defaults)
        #expect(service.storedDeviceToken == nil)
    }

    @Test("storeDeviceToken swallows keychain save failures without crashing")
    func storeDeviceTokenSwallowsFailure() {
        let keychain = FailingKeychainStore()
        let defaults = freshDefaults()
        let service = LiveNotificationService(keychain: keychain, defaults: defaults)

        // Should not throw or trap — we just log a warning.
        service.storeDeviceToken(Data([0x01]))
        #expect(service.storedDeviceToken == nil)
    }

    @Test("Init migrates a legacy UserDefaults device token into the keychain")
    func initMigratesLegacyToken() {
        let keychain = InMemoryKeychainStore()
        let defaults = freshDefaults()
        defaults.set("legacy-token", forKey: "pulse.deviceToken")

        let service = LiveNotificationService(keychain: keychain, defaults: defaults)

        // Legacy UserDefaults entry removed.
        #expect(defaults.object(forKey: "pulse.deviceToken") == nil)
        // Token moved into keychain.
        #expect(service.storedDeviceToken == "legacy-token")
    }

    @Test("Init is a no-op when no legacy UserDefaults token exists")
    func initNoOpWithoutLegacyToken() {
        let keychain = InMemoryKeychainStore()
        let defaults = freshDefaults()
        let service = LiveNotificationService(keychain: keychain, defaults: defaults)
        #expect(service.storedDeviceToken == nil)
        #expect(keychain.savedKeys.isEmpty)
    }
}
