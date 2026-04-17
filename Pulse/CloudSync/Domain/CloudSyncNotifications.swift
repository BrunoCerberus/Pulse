import Foundation

extension Notification.Name {
    /// Posted by `CloudSyncDomainInteractor` each time the underlying
    /// `NSPersistentCloudKitContainer` reports a successful sync. Feature
    /// interactors (Bookmarks, Reading History, Settings, Home) subscribe to
    /// refresh their state from storage after merges arrive from remote.
    static let cloudSyncDidComplete = Notification.Name("cloudSyncDidComplete")
}
