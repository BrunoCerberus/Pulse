import Foundation

extension Notification.Name {
    /// Posted by `LiveInterestProfileService` after every mutation to the
    /// interest-profile store (upsert / remove / reset / seed). The For You
    /// surface and Settings page subscribe to this to refresh from storage.
    static let interestProfileDidChange = Notification.Name("interestProfileDidChange")
}
