import Foundation
@testable import Pulse
import Testing

@Suite("PulseError Tests")
struct PulseErrorTests {
    @Test("offlineNoCache isOfflineError returns true")
    func offlineNoCacheIsOfflineError() {
        let error = PulseError.offlineNoCache
        #expect(error.isOfflineError)
    }

    @Test("offlineNoCache has error description")
    func offlineNoCacheHasErrorDescription() throws {
        let error = PulseError.offlineNoCache
        let description = try #require(error.errorDescription)
        #expect(!description.isEmpty)
    }

    @Test("offlineNoCache localizedDescription is not empty")
    func offlineNoCacheLocalizedDescription() {
        let error = PulseError.offlineNoCache
        #expect(!error.localizedDescription.isEmpty)
    }

    @Test("Generic error isOfflineError returns false")
    func genericErrorIsNotOffline() {
        let error = NSError(domain: "test", code: 1)
        #expect(!error.isOfflineError)
    }

    @Test("URL error isOfflineError returns false")
    func urlErrorIsNotOffline() {
        let error = URLError(.notConnectedToInternet)
        #expect(!error.isOfflineError)
    }

    @Test("PulseError cast as Error still detects offline")
    func pulseErrorAsErrorDetectsOffline() {
        let error: Error = PulseError.offlineNoCache
        #expect(error.isOfflineError)
    }
}
