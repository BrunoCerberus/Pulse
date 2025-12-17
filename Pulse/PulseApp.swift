import SwiftUI

@main
struct PulseApp: App {
    @UIApplicationDelegateAdaptor(PulseAppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
