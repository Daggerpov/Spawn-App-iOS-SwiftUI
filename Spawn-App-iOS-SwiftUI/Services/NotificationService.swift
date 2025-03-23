import Foundation
import UserNotifications
import SwiftUI

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isNotificationsEnabled = false
    
    // Notification preference properties
    @Published var friendRequestsEnabled: Bool = true
    @Published var eventInvitesEnabled: Bool = true
    @Published var eventUpdatesEnabled: Bool = true
    @Published var chatMessagesEnabled: Bool = true
    @Published var isLoadingPreferences: Bool = false
    
    // APIService instance to use for all API calls
    private let apiService: IAPIService
    
    private init() {
        // Use MockAPIService if in mocking mode, otherwise use regular APIService
        self.apiService = MockAPIService.isMocking
            ? MockAPIService(userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID())
            : APIService()
            
        checkNotificationStatus()
        // Load saved preferences from UserDefaults
        loadPreferencesFromUserDefaults()
        // Then try to fetch from backend
        Task {
            await fetchNotificationPreferences()
        }
    }
    
    // For testing: initialize with a mock API service
    init(mockAPIService: IAPIService) {
        self.apiService = mockAPIService
        checkNotificationStatus()
        loadPreferencesFromUserDefaults()
    }
    
    // Check if notifications are enabled
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Request notification permissions
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            DispatchQueue.main.async {
                self.isNotificationsEnabled = granted
            }
            return granted
        } catch {
            print("Error requesting notification permission: \(error.localizedDescription)")
            return false
        }
    }
    
    // Register device token with backend
    func registerDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token: \(tokenString)")
        
        // Send token to backend
        sendTokenToBackend(tokenString)
    }
    
    private func sendTokenToBackend(_ token: String) {
        // Only proceed if user is logged in and has an ID
        if let userId = UserAuthViewModel.shared.spawnUser?.id,
           let url = URL(string: "\(APIService.baseURL)users/\(userId)/deviceToken") {
            
            // Create device token DTO
            let deviceTokenDTO = DeviceTokenDTO(
                deviceToken: token,
                platform: "iOS",
                userId: userId
            )
            
            Task {
                do {
                    // Using sendData the standard way as in view models
                    _ = try await self.apiService.sendData(
                        deviceTokenDTO, 
                        to: url,
                        parameters: nil
                    )
                    print("Successfully registered device token with backend")
                } catch {
                    print("Failed to register device token: \(error.localizedDescription)")
                }
            }
        } else {
            print("Cannot register device token: user not logged in or missing ID")
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
        guard let typeString = userInfo["type"] as? String,
              let notificationType = NotificationType(rawValue: typeString) else {
            print("Notification missing or invalid type info")
            return
        }
        
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
            print("Received welcome notification")
            // No special handling needed
        }
    }
    
    // Handle friend request notifications
    private func handleFriendRequestNotification(_ userInfo: [AnyHashable: Any]) {
        guard let senderId = userInfo["senderId"] as? String,
              let requestId = userInfo["requestId"] as? String else { return }
        
        print("Friend request from user \(senderId), request ID: \(requestId)")
        // Navigate to friend requests view (implementation will depend on your navigation setup)
    }
    
    // Handle event invite notifications
    private func handleEventInviteNotification(_ userInfo: [AnyHashable: Any]) {
        guard let eventId = userInfo["eventId"] as? String,
              let eventName = userInfo["eventName"] as? String else { return }
        
        print("Invited to event \(eventName), ID: \(eventId)")
        // Navigate to event details (implementation will depend on your navigation setup)
    }
    
    // Handle event update notifications
    private func handleEventUpdateNotification(_ userInfo: [AnyHashable: Any]) {
        guard let eventId = userInfo["eventId"] as? String,
              let updateType = userInfo["updateType"] as? String else { return }
        
        print("Event update (\(updateType)) for event ID: \(eventId)")
        // Navigate to updated event (implementation will depend on your navigation setup)
    }
    
    // Handle chat message notifications
    private func handleChatNotification(_ userInfo: [AnyHashable: Any]) {
        guard let eventId = userInfo["eventId"] as? String,
              let senderId = userInfo["senderId"] as? String else { return }
        
        print("New chat message in event \(eventId) from user \(senderId)")
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
            userInfo = NotificationDataBuilder.friendRequest(
                senderId: UUID(),
                requestId: UUID()
            )
            
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
            userInfo = NotificationDataBuilder.chatMessage(
                eventId: UUID(),
                senderId: UUID()
            )
            
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
        
        // Don't fetch from backend if in mock mode
        if MockAPIService.isMocking {
            print("Using default notification preferences in mock mode")
            return
        }
        
        isLoadingPreferences = true
        defer { isLoadingPreferences = false }
        
        if let url = URL(string: "\(APIService.baseURL)users/\(userId)/notificationPreferences") {
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
                
                print("Successfully fetched notification preferences")
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
        
        if let url = URL(string: "\(APIService.baseURL)users/\(userId)/notificationPreferences") {
            do {
                // Using sendData the standard way as in view models
                _ = try await self.apiService.sendData(
                    preferences,
                    to: url,
                    parameters: nil
                )
                print("Successfully updated notification preferences")
            } catch {
                print("Failed to update notification preferences: \(error.localizedDescription)")
            }
        }
    }
} 