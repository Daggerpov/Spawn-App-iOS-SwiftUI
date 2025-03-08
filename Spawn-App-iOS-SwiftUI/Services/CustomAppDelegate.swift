import SwiftUI
import UserNotifications

class CustomAppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    // This gives us access to the methods from our main app code inside the app delegate
    var app: (any App)?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register this device to receive push notifications from Apple
        application.registerForRemoteNotifications()
        
        // Setting the notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Once the device is registered for push notifications, Apple sends the token to our app
        // This is where we would forward the token to our push server
        let stringifiedToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token for Push Notifications:", stringifiedToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Called when registration for remote notifications fails
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// Extend the CustomAppDelegate to handle notification events
extension CustomAppDelegate: UNUserNotificationCenterDelegate {
    // This function lets us do something when the user interacts with a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        print("User interacted with notification: ", response.notification.request.content.title)
        
        // You can handle different notification actions here and navigate to specific views
    }
    
    // This function allows us to view notifications with the app in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // These options are used when displaying a notification with the app in the foreground
        return [.badge, .banner, .list, .sound]
    }
} 
