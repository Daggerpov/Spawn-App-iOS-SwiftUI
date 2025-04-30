import SwiftUI
import UserNotifications
import FirebaseCore
import FirebaseMessaging

class CustomAppDelegate: NSObject, UIApplicationDelegate, ObservableObject, MessagingDelegate {
    // This gives us access to the methods from our main app code inside the app delegate
    var app: (any App)?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Initialize app cache
        AppCache.shared.initialize()
        
        // Register for remote notifications
        NotificationService.shared.registerForPushNotifications()
        
        FirebaseApp.configure()
        
        // Setting the notification delegate
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

//        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//        UNUserNotificationCenter.current().requestAuthorization(
//          options: authOptions,
//          completionHandler: { _, _ in }
//        )
//
//        application.registerForRemoteNotifications()
        // Handle notification that launched the app
        if let notification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            print("[PUSH DEBUG] App launched from notification: \(notification)")
            handleReceivedNotification(notification)
        }
        
        return true
    }
    
    // Handle device token registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("Device token: \(deviceToken)")
        NotificationService.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    // Handle registration failures
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationService.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    // Handle when the app is launched from a notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Validate cache when app is opened from a notification
        Task {
            await AppCache.shared.validateCache()
            completionHandler(.newData)
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let deviceToken = fcmToken {
            print("✅ FCM registration token: \(deviceToken)")
            print("Sending registration token to server")
            NotificationService.shared.registerDeviceToken(deviceToken)
        } else {
            print("[PUSH ERROR] Failed to receive registration token")
        }
    }
    
    // Handle notification data
    private func handleReceivedNotification(_ userInfo: [AnyHashable: Any]) {
        print("[PUSH DEBUG] Processing notification: \(userInfo)")
        
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
        print("[PUSH DEBUG] User interacted with notification: \(response.notification.request.content.title)")
        print("[PUSH DEBUG] Notification action: \(response.actionIdentifier)")
        print("[PUSH DEBUG] Notification userInfo: \(userInfo)")
        
        // Process the notification based on its type
        handleReceivedNotification(userInfo)
    }
    
    // This function allows us to view notifications with the app in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        print("[PUSH DEBUG] Will present notification in foreground: \(notification.request.content.title)")
        print("[PUSH DEBUG] Notification userInfo: \(notification.request.content.userInfo)")
        
        // These options are used when displaying a notification with the app in the foreground
        return [.badge, .banner, .list, .sound]
    }
} 
