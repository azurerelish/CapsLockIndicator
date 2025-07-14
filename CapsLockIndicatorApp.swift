import SwiftUI

@main
struct CapsLockIndicatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // No window scene needed for menu bar only app
        Settings {
            EmptyView()
        }
    }
}
