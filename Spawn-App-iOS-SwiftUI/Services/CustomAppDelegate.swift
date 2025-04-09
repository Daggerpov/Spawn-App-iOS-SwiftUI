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
        
        // Handle notification that launched the app
        if let notification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            handleReceivedNotification(notification)
        }
        
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Forward the token to our notification service
        NotificationService.shared.registerDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Called when registration for remote notifications fails
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // Handle push notifications that arrived while the app was in the background
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Check if this notification is for cache invalidation
        if let type = userInfo["type"] as? String {
            switch type {
            case "friend-updated", "friend-accepted":
                // Someone accepted a friend request or updated their profile
                Task {
                    await AppCache.shared.refreshFriends()
                    completionHandler(.newData)
                }
                return
                
            case "event-updated":
                // An event was updated
                Task {
                    await AppCache.shared.refreshEvents()
                    completionHandler(.newData)
                }
                return
                
            case "new-notification":
                // New notification received
                Task {
                    await AppCache.shared.refreshNotifications()
                    completionHandler(.newData)
                }
                return
                
            default:
                break
            }
        }
        
        // Process standard notification if not a cache invalidation notification
        NotificationService.shared.processNotification(userInfo: userInfo)
        completionHandler(.newData)
    }
    
    // Handle notification data
    private func handleReceivedNotification(_ userInfo: [AnyHashable: Any]) {
        // Forward to our notification service
        NotificationService.shared.handleNotification(userInfo: userInfo)
    }
}

// Extend the CustomAppDelegate to handle notification events
extension CustomAppDelegate: UNUserNotificationCenterDelegate {
    // This function lets us do something when the user interacts with a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Get the notification data
        let userInfo = response.notification.request.content.userInfo
        print("User interacted with notification: ", response.notification.request.content.title)
        
        // Process the notification based on its type
        handleReceivedNotification(userInfo)
    }
    
    // This function allows us to view notifications with the app in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // These options are used when displaying a notification with the app in the foreground
        return [.badge, .banner, .list, .sound]
    }
} 
