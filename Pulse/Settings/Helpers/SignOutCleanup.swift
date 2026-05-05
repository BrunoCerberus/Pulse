import CloudKit
import EntropyCore
import Foundation
import Security

/// Cleanup steps that must run on sign-out and account deletion.
///
/// Kept out of `SettingsViewModel` so the view model stays focused on UI
/// state and these helpers can be unit-tested without `@MainActor` or a
/// `ServiceLocator`. All entry points are best-effort: failures log a
/// warning but never throw, so a partial cleanup never blocks the user
/// from completing sign-out.
enum SignOutCleanup {
    /// Removes every keychain item under the given service identifiers.
    /// `errSecItemNotFound` is a benign "nothing to delete" outcome and
    /// is ignored. Any other non-success status is logged.
    static func wipeKeychain(services: [String]) {
        for service in services {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
            ]
            let status = SecItemDelete(query as CFDictionary)
            guard status != errSecSuccess, status != errSecItemNotFound else { continue }
            Logger.shared.service(
                "Failed to wipe keychain service \(service): OSStatus \(status)",
                level: .warning
            )
        }
    }

    /// Deletes every record zone in the app's private CloudKit DB so that
    /// reinstalling on the same iCloud account does not resurrect synced
    /// bookmarks / reading history.
    ///
    /// We can't hardcode a zone ID: SwiftData's CloudKit mirroring writes to
    /// `com.apple.coredata.cloudkit.zone` rather than `_defaultZone`, and the
    /// exact name is an implementation detail that may change. Enumerating
    /// `allRecordZones()` covers the SwiftData zone today and any zones we
    /// might add later (additional models, shared zones) without coupling
    /// this helper to Apple's internal naming.
    static func deletePrivateCloudKitZones(_ containerIdentifier: String) {
        Task.detached(priority: .utility) {
            let database = CKContainer(identifier: containerIdentifier).privateCloudDatabase
            do {
                let zones = try await database.allRecordZones()
                guard !zones.isEmpty else {
                    Logger.shared.service("CloudKit private DB had no zones to delete", level: .info)
                    return
                }
                let zoneIDs = zones.map(\.zoneID)
                _ = try await database.modifyRecordZones(saving: [], deleting: zoneIDs)
                Logger.shared.service(
                    "CloudKit private zones deleted on sign-out (\(zoneIDs.count))",
                    level: .info
                )
            } catch {
                Logger.shared.service(
                    "CloudKit zone delete failed (non-fatal): \(error.localizedDescription)",
                    level: .warning
                )
            }
        }
    }
}
