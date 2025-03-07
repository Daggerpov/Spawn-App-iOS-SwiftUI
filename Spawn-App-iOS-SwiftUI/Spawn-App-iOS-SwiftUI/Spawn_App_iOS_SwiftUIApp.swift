import SwiftUI

@main
struct Spawn_App_iOS_SwiftUIApp: App {
    // Add UIApplicationDelegateAdaptor for push notifications
    @UIApplicationDelegateAdaptor private var appDelegate: CustomAppDelegate
    
    var body: some Scene {
        WindowGroup {
            LaunchView()
                .onAppear {
                    // Connect the app delegate to the app
                    appDelegate.app = self
                }
        }
    }
} 