import Foundation

extension Notification.Name {
    /// Posted when the app coordinator becomes available for deeplink routing.
    ///
    /// **Publisher**: CoordinatorView (on appear)
    /// **Listeners**: DeeplinkRouter
    /// **Payload**: `object` contains the Coordinator instance
    ///
    /// This notification enables deeplink handling by making the coordinator available
    /// to the DeeplinkRouter, which processes incoming URLs and navigates accordingly.
    static let coordinatorDidBecomeAvailable = Notification.Name("coordinatorDidBecomeAvailable")
}
