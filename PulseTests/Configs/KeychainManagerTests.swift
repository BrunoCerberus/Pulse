import Foundation
@testable import Pulse
import Testing

/// Note: Keychain tests require host app entitlements to run.
/// These tests are disabled in unit test target but can run in UI tests.
@Suite("KeychainManager Tests", .serialized, .disabled("Keychain requires host app entitlements"))
@MainActor
struct KeychainManagerTests {
    let sut: KeychainManager
    let testService = "com.pulse.tests.keychain"

    init() {
        sut = KeychainManager(service: testService)
        // Clean up any existing test keys
        try? sut.delete(for: "testKey")
        try? sut.delete(for: "testKey1")
        try? sut.delete(for: "testKey2")
        try? sut.delete(for: "updateKey")
        try? sut.delete(for: "existsKey")
        try? sut.delete(for: "deleteKey")
    }

    // MARK: - Save Tests

    @Test("Save stores value in keychain")
    func saveStoresValue() throws {
        try sut.save("testValue", for: "testKey")
        defer { try? sut.delete(for: "testKey") }

        let retrieved = try sut.retrieve(for: "testKey")
        #expect(retrieved == "testValue")
    }

    @Test("Save updates existing value")
    func saveUpdatesExistingValue() throws {
        try sut.save("originalValue", for: "updateKey")
        try sut.save("updatedValue", for: "updateKey")
        defer { try? sut.delete(for: "updateKey") }

        let retrieved = try sut.retrieve(for: "updateKey")
        #expect(retrieved == "updatedValue")
    }

    @Test("Save handles special characters")
    func saveHandlesSpecialCharacters() throws {
        let specialValue = "p@ssw0rd!#$%^&*()_+-=[]{}|;':\",./<>?"
        try sut.save(specialValue, for: "testKey")
        defer { try? sut.delete(for: "testKey") }

        let retrieved = try sut.retrieve(for: "testKey")
        #expect(retrieved == specialValue)
    }

    @Test("Save handles unicode characters")
    func saveHandlesUnicodeCharacters() throws {
        let unicodeValue = "日本語テスト 🎉 emoji 中文"
        try sut.save(unicodeValue, for: "testKey")
        defer { try? sut.delete(for: "testKey") }

        let retrieved = try sut.retrieve(for: "testKey")
        #expect(retrieved == unicodeValue)
    }

    @Test("Save handles empty string")
    func saveHandlesEmptyString() throws {
        try sut.save("", for: "testKey")
        defer { try? sut.delete(for: "testKey") }

        let retrieved = try sut.retrieve(for: "testKey")
        #expect(retrieved == "")
    }

    @Test("Save handles long string")
    func saveHandlesLongString() throws {
        let longValue = String(repeating: "a", count: 10000)
        try sut.save(longValue, for: "testKey")
        defer { try? sut.delete(for: "testKey") }

        let retrieved = try sut.retrieve(for: "testKey")
        #expect(retrieved == longValue)
    }

    // MARK: - Retrieve Tests

    @Test("Retrieve throws for non-existent key")
    func retrieveThrowsForNonExistentKey() {
        #expect(throws: KeychainManager.KeychainError.self) {
            _ = try sut.retrieve(for: "nonExistentKey")
        }
    }

    @Test("Retrieve returns correct value for existing key")
    func retrieveReturnsCorrectValue() throws {
        try sut.save("mySecret", for: "testKey")
        defer { try? sut.delete(for: "testKey") }

        let value = try sut.retrieve(for: "testKey")
        #expect(value == "mySecret")
    }

    // MARK: - Delete Tests

    @Test("Delete removes existing key")
    func deleteRemovesExistingKey() throws {
        try sut.save("toDelete", for: "deleteKey")

        try sut.delete(for: "deleteKey")

        #expect(!sut.exists(for: "deleteKey"))
    }

    @Test("Delete does not throw for non-existent key")
    func deleteDoesNotThrowForNonExistentKey() throws {
        // Should not throw
        try sut.delete(for: "nonExistentKey")
    }

    @Test("Delete makes retrieve throw")
    func deleteMakesRetrieveThrow() throws {
        try sut.save("value", for: "deleteKey")
        try sut.delete(for: "deleteKey")

        #expect(throws: KeychainManager.KeychainError.self) {
            _ = try sut.retrieve(for: "deleteKey")
        }
    }

    // MARK: - Exists Tests

    @Test("Exists returns true for existing key")
    func existsReturnsTrueForExistingKey() throws {
        try sut.save("value", for: "existsKey")
        defer { try? sut.delete(for: "existsKey") }

        #expect(sut.exists(for: "existsKey"))
    }

    @Test("Exists returns false for non-existent key")
    func existsReturnsFalseForNonExistentKey() {
        #expect(!sut.exists(for: "nonExistentKey"))
    }

    @Test("Exists returns false after delete")
    func existsReturnsFalseAfterDelete() throws {
        try sut.save("value", for: "existsKey")
        try sut.delete(for: "existsKey")

        #expect(!sut.exists(for: "existsKey"))
    }

    // MARK: - Service Isolation Tests

    @Test("Different services are isolated")
    func differentServicesAreIsolated() throws {
        let service1 = KeychainManager(service: "com.pulse.tests.service1")
        let service2 = KeychainManager(service: "com.pulse.tests.service2")

        try service1.save("value1", for: "sharedKey")
        defer { try? service1.delete(for: "sharedKey") }

        #expect(!service2.exists(for: "sharedKey"))
    }

    @Test("Same key different services have different values")
    func sameKeyDifferentServicesHaveDifferentValues() throws {
        let service1 = KeychainManager(service: "com.pulse.tests.serviceA")
        let service2 = KeychainManager(service: "com.pulse.tests.serviceB")

        try service1.save("valueA", for: "key")
        try service2.save("valueB", for: "key")
        defer {
            try? service1.delete(for: "key")
            try? service2.delete(for: "key")
        }

        #expect(try service1.retrieve(for: "key") == "valueA")
        #expect(try service2.retrieve(for: "key") == "valueB")
    }

    // MARK: - Error Description Tests

    @Test("KeychainError has error descriptions")
    func keychainErrorHasDescriptions() throws {
        let errors: [KeychainManager.KeychainError] = [
            .duplicateEntry,
            .unknown(0),
            .itemNotFound,
            .invalidItemFormat,
            .unhandledError(status: -25300),
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(try !(#require(error.errorDescription?.isEmpty)))
        }
    }
}
