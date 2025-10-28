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
        // Only validate cache if user is logged in
        guard UserAuthViewModel.shared.isLoggedIn, UserAuthViewModel.shared.spawnUser != nil else {
            print("[PUSH DEBUG] Skipping cache validation - no logged in user")
            completionHandler(.noData)
            return
        }
        
        // Validate cache when app is opened from a notification
        Task {
            await AppCache.shared.validateCache()
            completionHandler(.newData)
        }
    }
    
    // Handle when app will enter foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("🔄 CustomAppDelegate: App will enter foreground")
        
        // Only refresh if user is logged in
        guard UserAuthViewModel.shared.isLoggedIn, UserAuthViewModel.shared.spawnUser != nil else {
            print("🔄 Skipping refresh - no logged in user")
            return
        }
        
        print("🔄 Refreshing activities for logged in user")
        Task {
            await AppCache.shared.refreshActivities()
            // Notify all listeners to refresh activities
            NotificationCenter.default.post(name: .shouldRefreshActivities, object: nil)
        }
    }
    
    // Handle when app becomes active
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("🔄 CustomAppDelegate: App became active")
        
        // Only cleanup if user is logged in
        guard UserAuthViewModel.shared.isLoggedIn, UserAuthViewModel.shared.spawnUser != nil else {
            print("🔄 Skipping cleanup - no logged in user")
            return
        }
        
        // Additional refresh if needed
        Task {
            AppCache.shared.cleanupExpiredActivities()
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
        
        // Also handle cache updates
        NotificationService.shared.handleNotificationData(userInfo)
    }
    
    // This function allows us to view notifications with the app in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        print("[PUSH DEBUG] Will present notification in foreground: \(notification.request.content.title)")
        print("[PUSH DEBUG] Notification userInfo: \(notification.request.content.userInfo)")
        
        // Show in-app notification instead of system notification when app is in foreground
        await MainActor.run {
            InAppNotificationManager.shared.showNotificationFromPushData(notification.request.content.userInfo)
        }
        
        // Process the notification data for cache updates
        handleReceivedNotification(notification.request.content.userInfo)
        
        // Also handle cache updates
        NotificationService.shared.handleNotificationData(notification.request.content.userInfo)
        
        // Return badge and sound only (no banner since we're showing in-app notification)
        return [.badge, .sound]
    }
} 
