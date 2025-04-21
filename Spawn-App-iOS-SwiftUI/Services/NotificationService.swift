import Foundation
import UserNotifications
import SwiftUI

@available(iOS 16.0, *)
class NotificationService: ObservableObject, @unchecked Sendable, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    @Published var isNotificationsEnabled = false
    
    // Notification preference properties
    @Published var friendRequestsEnabled: Bool = true
    @Published var eventInvitesEnabled: Bool = true
    @Published var eventUpdatesEnabled: Bool = true
    @Published var chatMessagesEnabled: Bool = true
    @Published var isLoadingPreferences: Bool = false
    
    // Store the device token for later registration
    private var storedDeviceToken: String?
    
    // APIService instance to use for all API calls
    private let apiService: IAPIService
    
    private var appCache: AppCache {
        return AppCache.shared
    }
    
    private init() {
        // Use MockAPIService if in mocking mode, otherwise use regular APIService
        self.apiService = MockAPIService.isMocking
            ? MockAPIService(userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID())
            : APIService()
            
        checkNotificationStatus()
        // Load saved preferences from UserDefaults
        loadPreferencesFromUserDefaults()
        
        // Add observer for user login notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidLogin),
            name: .userDidLogin,
            object: nil
        )
        
        // Set this class as the delegate for notification center
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Register for push notifications
    func registerForPushNotifications() {
        // Request permission first
        Task {
            let granted = await requestPermission()
            if granted {
                // Register for remote notifications on main thread
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("[PUSH DEBUG] Registered for remote notifications")
                }
            } else {
                print("[PUSH DEBUG] Permission not granted for notifications")
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // For testing: initialize with a mock API service
    init(mockAPIService: IAPIService) {
        self.apiService = mockAPIService
        checkNotificationStatus()
        loadPreferencesFromUserDefaults()
    }
    
    // Called when user logs in
    @objc private func userDidLogin() {
        // If we have a stored token, register it now
        if storedDeviceToken != nil {
            registerStoredTokenWithBackend()
        }
        
        // Fetch notification preferences after login
        Task { [weak self] in
            await self?.fetchNotificationPreferences()
        }
    }
    
    // Check if notifications are enabled
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Request notification permissions
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            DispatchQueue.main.async { [weak self] in
                self?.isNotificationsEnabled = granted
            }
            return granted
        } catch {
            print("Error requesting notification permission: \(error.localizedDescription)")
            return false
        }
    }
    
    // Store device token when received from Apple
    func registerDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[PUSH DEBUG] Device token received: \(tokenString)")
        
        // Store the token for later use
        storedDeviceToken = tokenString
        
        // Only try to register with backend if user is already logged in
        if UserAuthViewModel.shared.isLoggedIn {
            print("[PUSH DEBUG] User is logged in, registering token with backend immediately")
            registerStoredTokenWithBackend()
        } else {
            print("[PUSH DEBUG] User not logged in yet. Token stored for later registration")
        }
    }
    
    // Register the stored token with the backend
    func registerStoredTokenWithBackend() {
        guard let token = storedDeviceToken else {
            print("No device token available to register")
            return
        }
        
        sendTokenToBackend(token)
    }
    
    private func sendTokenToBackend(_ token: String) {
        // Only proceed if user is logged in and has an ID
        if let userId = UserAuthViewModel.shared.spawnUser?.id,
           let url = URL(string: "\(APIService.baseURL)notifications/device-tokens/register") {
            
            print("[PUSH DEBUG] Preparing to send device token to backend URL: \(url)")
            
            // Create device token DTO
            let deviceTokenDTO = DeviceTokenDTO(
                token: token,
                deviceType: "IOS",
                userId: userId
            )
            
            print("[PUSH DEBUG] Device token payload: token=\(token.prefix(8))...(truncated), deviceType=IOS, userId=\(userId)")
            
            Task {
                do {
                    // Using sendData the standard way as in view models
                    _ = try await self.apiService.sendData(
                        deviceTokenDTO, 
                        to: url,
                        parameters: nil
                    )
                    print("[PUSH DEBUG] Successfully registered device token with backend")
                } catch let error as APIError {
                    // Check if it's a 404 error (endpoint doesn't exist yet)
                    if case .invalidStatusCode(let statusCode) = error, statusCode == 404 {
                        print("[PUSH DEBUG] Device token registration endpoint not available (404): Backend may not support push notifications yet")
                    } else {
                        print("[PUSH DEBUG] Failed to register device token: \(error.localizedDescription)")
                        print("[PUSH DEBUG] API Error details: \(error)")
                    }
                } catch {
                    print("[PUSH DEBUG] Failed to register device token: \(error.localizedDescription)")
                    print("[PUSH DEBUG] Error details: \(error)")
                }
            }
        } else {
            print("[PUSH DEBUG] Cannot register device token: user not logged in or missing ID")
            if UserAuthViewModel.shared.spawnUser == nil {
                print("[PUSH DEBUG] User not logged in (spawnUser is nil)")
            } else if let user = UserAuthViewModel.shared.spawnUser {
                print("[PUSH DEBUG] User logged in but ID is nil. Username: \(user.username)")
            }
            print("[PUSH DEBUG] APIService baseURL: \(APIService.baseURL)")
        }
    }
    
    // Display a local notification
    func scheduleLocalNotification(title: String, body: String, userInfo: [String: String]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Add app logo as attachment
        if let logoAttachment = createLogoAttachment() {
            content.attachments = [logoAttachment]
        }
        
        // Add all key-value pairs from userInfo to notification userInfo
        for (key, value) in userInfo {
            content.userInfo[key] = value
        }
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        // Create request with unique identifier
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, 
            content: content, 
            trigger: trigger
        )
        
        // Add to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Overloaded method for backward compatibility
    func scheduleLocalNotification(title: String, body: String, userInfo: [String: Any] = [:]) {
        var stringUserInfo: [String: String] = [:]
        
        // Convert Any values to String where possible
        for (key, value) in userInfo {
            if let stringValue = value as? String {
                stringUserInfo[key] = stringValue
            } else {
                // For non-string values, convert to string representation
                stringUserInfo[key] = "\(value)"
            }
        }
        
        scheduleLocalNotification(title: title, body: body, userInfo: stringUserInfo)
    }
    
    // Create notification attachment with app logo
    private func createLogoAttachment() -> UNNotificationAttachment? {
        // First try to use the exported logo
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let logoURL = tempDirectory.appendingPathComponent("app_logo.png")
        
        // If logo doesn't exist in temp directory, export it
        if !fileManager.fileExists(atPath: logoURL.path) {
            NotificationIconExporter.exportAppIconForNotifications()
        }
        
        // If logo now exists, use it
        if fileManager.fileExists(atPath: logoURL.path) {
            do {
                return try UNNotificationAttachment(
                    identifier: "logo",
                    url: logoURL,
                    options: [UNNotificationAttachmentOptionsThumbnailHiddenKey: false]
                )
            } catch {
                print("Error creating notification attachment: \(error.localizedDescription)")
            }
        }
        
        // Fallback to bundled resources if export failed
        if let url = Bundle.main.url(forResource: "spawn_launch_logo", withExtension: "png") ??
           Bundle.main.url(forResource: "Spawn_Glow", withExtension: "png") {
            do {
                return try UNNotificationAttachment(
                    identifier: "logo",
                    url: url, 
                    options: [UNNotificationAttachmentOptionsThumbnailHiddenKey: false]
                )
            } catch {
                print("Error creating notification attachment from bundle: \(error.localizedDescription)")
            }
        }
        
        return nil
    }
    
    // Handle different notification types
    func handleNotification(userInfo: [AnyHashable: Any]) {
        print("[PUSH DEBUG] Handling notification with payload: \(userInfo)")
        
        guard let typeString = userInfo["type"] as? String,
              let notificationType = NotificationType(rawValue: typeString) else {
            print("[PUSH DEBUG] Error: Notification missing or invalid type info")
            print("[PUSH DEBUG] Available keys in payload: \(userInfo.keys)")
            return
        }
        
        print("[PUSH DEBUG] Processing notification of type: \(notificationType.rawValue)")
        
        // Handle different notification types
        switch notificationType {
        case .friendRequest:
            handleFriendRequestNotification(userInfo)
        case .eventInvite:
            handleEventInviteNotification(userInfo)
        case .eventUpdate:
            handleEventUpdateNotification(userInfo)
        case .chat:
            handleChatNotification(userInfo)
        case .welcome:
            print("[PUSH DEBUG] Received welcome notification")
            // No special handling needed
        }
    }
    
    // Handle friend request notifications
    private func handleFriendRequestNotification(_ userInfo: [AnyHashable: Any]) {
        print("[PUSH DEBUG] Processing friend request notification with data: \(userInfo)")
        
        guard let senderId = userInfo["senderId"] as? String,
              let requestId = userInfo["requestId"] as? String else { 
            print("[PUSH DEBUG] Error: Missing required fields in friend request notification")
            print("[PUSH DEBUG] Available keys: \(userInfo.keys)")
            return 
        }
        
        // Get user info if available
        if let userId = UUID(uuidString: senderId), 
           let user = UserAuthViewModel.shared.spawnUser, 
           user.id == userId {
            print("[PUSH DEBUG] Friend request from user \(senderId) (username: \(user.username), name: \(user.firstName ?? "") \(user.lastName ?? "")), request ID: \(requestId)")
        } else {
            print("[PUSH DEBUG] Friend request from user \(senderId), request ID: \(requestId)")
        }
        // Navigate to friend requests view (implementation will depend on your navigation setup)
    }
    
    // Handle event invite notifications
    private func handleEventInviteNotification(_ userInfo: [AnyHashable: Any]) {
        print("[PUSH DEBUG] Processing event invite notification with data: \(userInfo)")
        
        guard let eventId = userInfo["eventId"] as? String,
              let eventName = userInfo["eventName"] as? String else { 
            print("[PUSH DEBUG] Error: Missing required fields in event invite notification")
            print("[PUSH DEBUG] Available keys: \(userInfo.keys)")
            return 
        }
        
        print("[PUSH DEBUG] Invited to event \(eventName), ID: \(eventId)")
        // Navigate to event details (implementation will depend on your navigation setup)
    }
    
    // Handle event update notifications
    private func handleEventUpdateNotification(_ userInfo: [AnyHashable: Any]) {
        print("[PUSH DEBUG] Processing event update notification with data: \(userInfo)")
        
        guard let eventId = userInfo["eventId"] as? String,
              let updateType = userInfo["updateType"] as? String else { 
            print("[PUSH DEBUG] Error: Missing required fields in event update notification")
            print("[PUSH DEBUG] Available keys: \(userInfo.keys)")
            return 
        }
        
        print("[PUSH DEBUG] Event update (\(updateType)) for event ID: \(eventId)")
        // Navigate to updated event (implementation will depend on your navigation setup)
    }
    
    // Handle chat message notifications
    private func handleChatNotification(_ userInfo: [AnyHashable: Any]) {
        print("[PUSH DEBUG] Processing chat notification with data: \(userInfo)")
        
        guard let eventId = userInfo["eventId"] as? String,
              let senderId = userInfo["senderId"] as? String else { 
            print("[PUSH DEBUG] Error: Missing required fields in chat notification")
            print("[PUSH DEBUG] Available keys: \(userInfo.keys)")
            return 
        }
        
        // Get user info if available
        if let userId = UUID(uuidString: senderId), 
           let user = UserAuthViewModel.shared.spawnUser, 
           user.id == userId {
            print("[PUSH DEBUG] New chat message in event \(eventId) from user \(senderId) (username: \(user.username), name: \(user.firstName ?? "") \(user.lastName ?? ""))")
        } else {
            print("[PUSH DEBUG] New chat message in event \(eventId) from user \(senderId)")
        }
        // Navigate to chat (implementation will depend on your navigation setup)
    }
    
    // Test notifications (for development)
    func sendTestNotification(type: String) {
        guard let notificationType = NotificationType(rawValue: type) else {
            print("Invalid notification type: \(type)")
            return
        }
        
        var title = ""
        var body = ""
        var userInfo: [String: String] = [:]
        
        switch notificationType {
        case .friendRequest:
            title = "New Friend Request"
            body = "Someone wants to be your friend on Spawn!"
            let senderId = UUID()
            userInfo = NotificationDataBuilder.friendRequest(
                senderId: senderId,
                requestId: UUID()
            )
            
            // Add more detailed logging
            if let user = UserAuthViewModel.shared.spawnUser {
                print("Test Friend Request - User ID: \(senderId) (username: \(user.username), name: \(user.firstName ?? "") \(user.lastName ?? ""))")
            }
            
        case .eventInvite:
            title = "New Event Invitation"
            body = "You've been invited to an event!"
            userInfo = NotificationDataBuilder.eventInvite(
                eventId: UUID(),
                eventName: "Fun Hangout"
            )
            
        case .eventUpdate:
            title = "Event Updated"
            body = "An event you're attending has been updated"
            userInfo = NotificationDataBuilder.eventUpdate(
                eventId: UUID(),
                updateType: "time"
            )
            
        case .chat:
            title = "New Message"
            body = "You have a new message in an event chat"
            let senderId = UUID()
            userInfo = NotificationDataBuilder.chatMessage(
                eventId: UUID(),
                senderId: senderId
            )
            
            // Add more detailed logging
            if let user = UserAuthViewModel.shared.spawnUser {
                print("Test Chat Message - User ID: \(senderId) (username: \(user.username), name: \(user.firstName ?? "") \(user.lastName ?? ""))")
            }
            
        case .welcome:
            title = "Welcome to Spawn!"
            body = "Thanks for joining. We'll keep you updated on events and friends."
            userInfo = NotificationDataBuilder.welcome()
        }
        
        scheduleLocalNotification(title: title, body: body, userInfo: userInfo)
    }
    
    // Save preferences to UserDefaults as a fallback
    private func loadPreferencesFromUserDefaults() {
        let defaults = UserDefaults.standard
        friendRequestsEnabled = defaults.bool(forKey: "friendRequestsEnabled")
        eventInvitesEnabled = defaults.bool(forKey: "eventInvitesEnabled")
        eventUpdatesEnabled = defaults.bool(forKey: "eventUpdatesEnabled")
        chatMessagesEnabled = defaults.bool(forKey: "chatMessagesEnabled")
    }
    
    private func savePreferencesToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(friendRequestsEnabled, forKey: "friendRequestsEnabled")
        defaults.set(eventInvitesEnabled, forKey: "eventInvitesEnabled")
        defaults.set(eventUpdatesEnabled, forKey: "eventUpdatesEnabled")
        defaults.set(chatMessagesEnabled, forKey: "chatMessagesEnabled")
    }
    
    // Fetch notification preferences from the backend
    @MainActor
    func fetchNotificationPreferences() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("Cannot fetch notification preferences: user not logged in")
            return
        }
        
        // Log user details
        if let user = UserAuthViewModel.shared.spawnUser {
            print("Fetching notification preferences for user ID: \(userId) (username: \(user.username), name: \(user.firstName ?? "") \(user.lastName ?? ""))")
        }
        
        // Don't fetch from backend if in mock mode
        if MockAPIService.isMocking {
            print("Using default notification preferences in mock mode")
            return
        }
        
        isLoadingPreferences = true
        defer { isLoadingPreferences = false }
        
        if let url = URL(string: "\(APIService.baseURL)notifications/preferences/\(userId)") {
            do {
                // Using fetchData the standard way as in view models
                let preferences: NotificationPreferencesDTO = try await self.apiService.fetchData(
                    from: url,
                    parameters: nil
                )
                
                // Update local state with fetched preferences
                friendRequestsEnabled = preferences.friendRequestsEnabled
                eventInvitesEnabled = preferences.eventInvitesEnabled
                eventUpdatesEnabled = preferences.eventUpdatesEnabled
                chatMessagesEnabled = preferences.chatMessagesEnabled
                
                // Save to UserDefaults as fallback
                savePreferencesToUserDefaults()
            } catch let error as APIError {
                // Check if it's a 404 error (endpoint doesn't exist yet)
                if case .invalidStatusCode(let statusCode) = error, statusCode == 404 {
                    print("Notification preferences endpoint not available (404): Using UserDefaults values")
                    // Continue using the UserDefaults values that were loaded in init()
                } else {
                    print("Failed to fetch notification preferences: \(error.localizedDescription)")
                }
            } catch {
                print("Failed to fetch notification preferences: \(error.localizedDescription)")
            }
        }
    }
    
    // Update notification preferences on the backend
    func updateNotificationPreferences() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("Cannot update notification preferences: user not logged in")
            return
        }
        
        // Log user details
        if let user = UserAuthViewModel.shared.spawnUser {
            print("Updating notification preferences for user ID: \(userId) (username: \(user.username), name: \(user.firstName ?? "") \(user.lastName ?? ""))")
        }
        
        // Save to UserDefaults immediately (optimistic update)
        savePreferencesToUserDefaults()
        
        // Don't update backend if in mock mode
        if MockAPIService.isMocking {
            print("Skipping backend update for notification preferences in mock mode")
            return
        }
        
        let preferences = NotificationPreferencesDTO(
            friendRequestsEnabled: friendRequestsEnabled,
            eventInvitesEnabled: eventInvitesEnabled,
            eventUpdatesEnabled: eventUpdatesEnabled,
            chatMessagesEnabled: chatMessagesEnabled,
            userId: userId
        )
        
        if let url = URL(string: "\(APIService.baseURL)notifications/preferences/\(userId)") {
            do {
                // Using sendData the standard way as in view models
                _ = try await self.apiService.sendData(
                    preferences,
                    to: url,
                    parameters: nil
                )
            } catch let error as APIError {
                // Check if it's a 404 error (endpoint doesn't exist yet)
                if case .invalidStatusCode(let statusCode) = error, statusCode == 404 {
                    print("Notification preferences endpoint not available (404): Values saved to UserDefaults only")
                    // We've already saved to UserDefaults above, so just continue
                } else {
                    print("Failed to update notification preferences: \(error.localizedDescription)")
                }
            } catch {
                print("Failed to update notification preferences: \(error.localizedDescription)")
            }
        }
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        
        // Process notification
        handleNotificationData(userInfo)
        
        // Show the notification to the user
        completionHandler([.banner, .badge, .sound])
    }
    
    // Handle notifications when app is opened from a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Process notification
        handleNotificationData(userInfo)
        
        completionHandler()
    }
    
    // Handle notification data and update cache accordingly
    private func handleNotificationData(_ userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else {
            print("Notification missing type")
            return
        }
        
        Task {
            switch type {
            case "friend-accepted":
                // When a friend request is accepted, refresh friends
                await appCache.refreshFriends()
                
            case "event-updated":
                // When an event is updated, refresh events
                await appCache.refreshEvents()
                
            case "friend-request":
                // When a new friend request is received, refresh friend requests
                await appCache.refreshFriendRequests()
            
            case "profile-updated":
                // When a friend's profile is updated, refresh other profiles
                if let userId = userInfo["userId"] as? String, 
                   let uuid = UUID(uuidString: userId) {
                    // Check if this is a profile we already have cached
                    if appCache.otherProfiles[uuid] != nil {
                        await appCache.refreshOtherProfiles()
                    }
                }
                
            case "tag-updated":
                // When a tag is updated, refresh tags
                await appCache.refreshUserTags()
                await appCache.refreshTagFriends()
                
            default:
                print("Unknown notification type: \(type)")
                // For unknown notification types, validate the entire cache
                await appCache.validateCache()
            }
        }
    }
}

// Extension for handling device token registration
extension NotificationService {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // Here you would send the token to your server
        sendDeviceTokenToServer(token)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for notifications: \(error.localizedDescription)")
    }
    
    private func sendDeviceTokenToServer(_ token: String) {
        // Implement to send token to your server
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        Task {
            do {
                guard let url = URL(string: APIService.baseURL + "users/\(userId)/device-token") else { return }
                
                let apiService: IAPIService = MockAPIService.isMocking ? 
                    MockAPIService(userId: userId) : APIService()
                
                let tokenData = ["deviceToken": token]
                _ = try await apiService.patchData(from: url, with: tokenData) as EmptyResponse
                
                print("Device token successfully sent to server")
            } catch {
                print("Failed to send device token: \(error)")
            }
        }
    }
} 
