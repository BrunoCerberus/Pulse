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

    /// Deletes the app's private CloudKit zone so reinstalling on the same
    /// iCloud account does not resurrect synced bookmarks / reading history.
    static func deletePrivateCloudKitZone(_ containerIdentifier: String) {
        let zoneID = CKRecordZone.ID(zoneName: CKRecordZone.ID.defaultZoneName)
        CKContainer(identifier: containerIdentifier)
            .privateCloudDatabase
            .delete(withRecordZoneID: zoneID) { _, error in
                if let error {
                    Logger.shared.service(
                        "CloudKit zone delete failed (non-fatal): \(error.localizedDescription)",
                        level: .warning
                    )
                } else {
                    Logger.shared.service("CloudKit private zone deleted on sign-out", level: .info)
                }
            }
    }
}
