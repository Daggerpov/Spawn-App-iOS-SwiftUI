import FirebaseMessaging
import Foundation
import SwiftUI
import UserNotifications

@available(iOS 16.0, *)
@MainActor
final class NotificationService: NSObject, ObservableObject {
	static let shared = NotificationService()

	@Published var isNotificationsEnabled = false

	// Notification preference properties
	@Published var friendRequestsEnabled: Bool = true
	@Published var activityInvitesEnabled: Bool = true
	@Published var activityUpdatesEnabled: Bool = true
	@Published var chatMessagesEnabled: Bool = true
	@Published var isLoadingPreferences: Bool = false

	// Store the device token for later registration
	private var storedDeviceToken: String?

	// APIService instance to use for all API calls
	private let apiService: IAPIService

	private var appCache: AppCache {
		return AppCache.shared
	}

	override private init() {
		// Use MockAPIService if in mocking mode, otherwise use regular APIService
		self.apiService =
			MockAPIService.isMocking
			? MockAPIService(userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID())
			: APIService()

		super.init()

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

		// Note: CustomAppDelegate handles UNUserNotificationCenterDelegate
		// Don't set delegate here to avoid conflicts
	}

	// Register for push notifications
	func registerForPushNotifications() {
		// Request permission first
		Task { @MainActor in
			let granted = await requestPermission()
			if granted {
				// Register for remote notifications on main thread
				UIApplication.shared.registerForRemoteNotifications()
			}
		}
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	// For testing: initialize with a mock API service
	init(mockAPIService: IAPIService) {
		self.apiService = mockAPIService
		super.init()
		checkNotificationStatus()
		loadPreferencesFromUserDefaults()
	}

	// Called when user logs in
	@objc private func userDidLogin() {
		// If we have a stored token, register it now
		registerForPushNotifications()

		// Fetch notification preferences after login
		Task { [weak self] in
			await self?.fetchNotificationPreferences()
		}
	}

	// Check if notifications are enabled
	func checkNotificationStatus() {
		Task { @MainActor in
			let settings = await UNUserNotificationCenter.current().notificationSettings()
			isNotificationsEnabled = settings.authorizationStatus == .authorized
		}
	}

	// Request notification permissions
	func requestPermission() async -> Bool {
		do {
			let granted = try await UNUserNotificationCenter.current().requestAuthorization(
				options: [.alert, .badge, .sound]
			)
			await MainActor.run {
				isNotificationsEnabled = granted
			}
			return granted
		} catch {
			AppLog.warning("Error requesting notification permission: \(error.localizedDescription)", category: "Push")
			return false
		}
	}

	// Store device token when received from Apple
	func registerDeviceToken(_ deviceToken: String) {
		AppLog.debug("Device token received: \(deviceToken)", category: "Push")

		// Store the token for later use
		storedDeviceToken = deviceToken

		// Only try to register with backend if user is already logged in
		if UserAuthViewModel.shared.isLoggedIn {
			AppLog.debug("User is logged in, registering token with backend immediately", category: "Push")
			registerStoredTokenWithBackend()
		} else {
			AppLog.debug("User not logged in yet. Token stored for later registration", category: "Push")
		}
	}

	// Register the stored token with the backend
	func registerStoredTokenWithBackend() {
		guard let token = storedDeviceToken else {
			AppLog.debug("No device token available to register", category: "Push")
			return
		}
		sendTokenToBackend(token)
	}

	private func sendTokenToBackend(_ token: String) {
		// Only proceed if user is logged in and has an ID
		if let userId = UserAuthViewModel.shared.spawnUser?.id,
			let url = URL(string: "\(APIService.baseURL)notifications/device-tokens")
		{

			// Create device token DTO
			let deviceTokenDTO = DeviceTokenDTO(
				token: token,
				deviceType: "IOS",
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
					AppLog.debug("Successfully registered device token with backend", category: "Push")
				} catch let error as APIError {
					// Check if it's a 404 error (endpoint doesn't exist yet)
					if case .invalidStatusCode(let statusCode) = error, statusCode == 404 {
						AppLog.debug(
							"Device token registration endpoint not available (404): Backend may not support push notifications yet",
							category: "Push"
						)
					} else {
						AppLog.debug("Failed to register device token: \(error.localizedDescription)", category: "Push")
						AppLog.debug("API Error details: \(error)", category: "Push")
					}
				} catch {
					AppLog.debug("Failed to register device token: \(error.localizedDescription)", category: "Push")
					AppLog.debug("Error details: \(error)", category: "Push")
				}
			}
		} else {
			AppLog.debug("Cannot register device token: user not logged in or missing ID", category: "Push")
			if UserAuthViewModel.shared.spawnUser == nil {
				AppLog.debug("User not logged in (spawnUser is nil)", category: "Push")
			} else if let user = UserAuthViewModel.shared.spawnUser {
				AppLog.debug("User logged in but ID is nil. Username: \(user.username ?? "N/A")", category: "Push")
			}
			AppLog.debug("APIService baseURL: \(APIService.baseURL)", category: "Push")
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
				AppLog.warning("Error scheduling notification: \(error.localizedDescription)", category: "Push")
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
				AppLog.warning(
					"Error creating notification attachment: \(error.localizedDescription)", category: "Push")
			}
		}

		// Fallback to bundled resources if export failed
		if let url = Bundle.main.url(forResource: "SpawnLogo", withExtension: "png")
			?? Bundle.main.url(forResource: "Spawn_Glow", withExtension: "png")
		{
			do {
				return try UNNotificationAttachment(
					identifier: "logo",
					url: url,
					options: [UNNotificationAttachmentOptionsThumbnailHiddenKey: false]
				)
			} catch {
				AppLog.warning(
					"Error creating notification attachment from bundle: \(error.localizedDescription)",
					category: "Push"
				)
			}
		}

		return nil
	}

	// Handle different notification types
	func handleNotification(userInfo: [AnyHashable: Any]) {
		AppLog.debug("Handling notification with payload: \(userInfo)", category: "Push")

		guard let typeString = userInfo["type"] as? String,
			let notificationType = NotificationType(rawValue: typeString)
		else {
			AppLog.debug("Error: Notification missing or invalid type info", category: "Push")
			AppLog.debug("Available keys in payload: \(userInfo.keys)", category: "Push")
			return
		}

		AppLog.debug("Processing notification of type: \(notificationType.rawValue)", category: "Push")

		// Handle different notification types
		switch notificationType {
		case .friendRequest:
			handleFriendRequestNotification(userInfo)
		case .activityInvite:
			handleActivityInviteNotification(userInfo)
		case .activityUpdate:
			handleActivityUpdateNotification(userInfo)
		case .chat:
			handleChatNotification(userInfo)
		case .welcome:
			AppLog.debug("Received welcome notification", category: "Push")
		// No special handling needed
		case .error:
			AppLog.debug("Received error notification", category: "Push")
		// Error notifications are typically local app errors, not push notifications
		case .success:
			AppLog.debug("Received success notification", category: "Push")
		// Success notifications are typically local app confirmations, not push notifications
		}
	}

	// Handle friend request notifications
	private func handleFriendRequestNotification(_ userInfo: [AnyHashable: Any]) {
		AppLog.debug("Processing friend request notification with data: \(userInfo)", category: "Push")

		guard let senderId = userInfo["senderId"] as? String,
			let requestId = userInfo["requestId"] as? String
		else {
			AppLog.debug("Error: Missing required fields in friend request notification", category: "Push")
			AppLog.debug("Available keys: \(userInfo.keys)", category: "Push")
			return
		}

		// Get user info if available
		if let userId = UUID(uuidString: senderId),
			let user = UserAuthViewModel.shared.spawnUser,
			user.id == userId
		{
			AppLog.debug(
				"Friend request from user \(senderId) (username: \(user.username ?? "Unknown"), name: \(user.name ?? "Unknown")), request ID: \(requestId)",
				category: "Push"
			)
		} else {
			AppLog.debug("Friend request from user \(senderId), request ID: \(requestId)", category: "Push")
		}
		// Navigate to friend requests view (implementation will depend on your navigation setup)
	}

	// Handle activity invite notifications
	private func handleActivityInviteNotification(_ userInfo: [AnyHashable: Any]) {
		AppLog.debug("Processing activity invite notification with data: \(userInfo)", category: "Push")

		guard let activityId = userInfo["activityId"] as? String,
			let activityName = userInfo["activityName"] as? String
		else {
			AppLog.debug("Error: Missing required fields in activity invite notification", category: "Push")
			AppLog.debug("Available keys: \(userInfo.keys)", category: "Push")
			return
		}

		AppLog.debug("Invited to activity \(activityName), ID: \(activityId)", category: "Push")
		// Navigate to activity details (implementation will depend on your navigation setup)
	}

	// Handle activity update notifications
	private func handleActivityUpdateNotification(_ userInfo: [AnyHashable: Any]) {
		AppLog.debug("Processing activity update notification with data: \(userInfo)", category: "Push")

		guard let activityId = userInfo["activityId"] as? String,
			let updateType = userInfo["updateType"] as? String
		else {
			AppLog.debug("Error: Missing required fields in activity update notification", category: "Push")
			AppLog.debug("Available keys: \(userInfo.keys)", category: "Push")
			return
		}

		AppLog.debug("Activity update (\(updateType)) for activity ID: \(activityId)", category: "Push")
		// Navigate to updated activity (implementation will depend on your navigation setup)
	}

	// Handle chat message notifications
	private func handleChatNotification(_ userInfo: [AnyHashable: Any]) {
		AppLog.debug("Processing chat notification with data: \(userInfo)", category: "Push")

		guard let activityId = userInfo["activityId"] as? String,
			let senderId = userInfo["senderId"] as? String
		else {
			AppLog.debug("Error: Missing required fields in chat notification", category: "Push")
			AppLog.debug("Available keys: \(userInfo.keys)", category: "Push")
			return
		}

		// Get user info if available
		if let userId = UUID(uuidString: senderId),
			let user = UserAuthViewModel.shared.spawnUser,
			user.id == userId
		{
			AppLog.debug(
				"New chat message in activity \(activityId) from user \(senderId) (username: \(user.username ?? "Unknown"), name: \(user.name ?? "Unknown"))",
				category: "Push"
			)
		} else {
			AppLog.debug("New chat message in activity \(activityId) from user \(senderId)", category: "Push")
		}
		// Navigate to chat (implementation will depend on your navigation setup)
	}

	// Save preferences to UserDefaults as a fallback (user-specific)
	private func loadPreferencesFromUserDefaults() {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id.uuidString else {
			// If no user is logged in, use default values
			friendRequestsEnabled = true
			activityInvitesEnabled = true
			activityUpdatesEnabled = true
			chatMessagesEnabled = true
			return
		}

		let defaults = UserDefaults.standard
		friendRequestsEnabled = defaults.bool(forKey: "friendRequestsEnabled_\(userId)")
		activityInvitesEnabled = defaults.bool(forKey: "activityInvitesEnabled_\(userId)")
		activityUpdatesEnabled = defaults.bool(forKey: "activityUpdatesEnabled_\(userId)")
		chatMessagesEnabled = defaults.bool(forKey: "chatMessagesEnabled_\(userId)")
	}

	private func savePreferencesToUserDefaults() {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id.uuidString else {
			AppLog.debug("Cannot save notification preferences: no user logged in", category: "Push")
			return
		}

		let defaults = UserDefaults.standard
		defaults.set(friendRequestsEnabled, forKey: "friendRequestsEnabled_\(userId)")
		defaults.set(activityInvitesEnabled, forKey: "activityInvitesEnabled_\(userId)")
		defaults.set(activityUpdatesEnabled, forKey: "activityUpdatesEnabled_\(userId)")
		defaults.set(chatMessagesEnabled, forKey: "chatMessagesEnabled_\(userId)")
	}

	/// Clear notification preferences for a specific user (useful when user logs out)
	func clearPreferencesForUser(_ userId: UUID) {
		let userIdString = userId.uuidString
		let defaults = UserDefaults.standard
		defaults.removeObject(forKey: "friendRequestsEnabled_\(userIdString)")
		defaults.removeObject(forKey: "activityInvitesEnabled_\(userIdString)")
		defaults.removeObject(forKey: "activityUpdatesEnabled_\(userIdString)")
		defaults.removeObject(forKey: "chatMessagesEnabled_\(userIdString)")
	}

	// Fetch notification preferences from the backend
	@MainActor
	func fetchNotificationPreferences() async {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			AppLog.debug("Cannot fetch notification preferences: user not logged in", category: "Push")
			return
		}

		// Don't fetch from backend if in mock mode
		if MockAPIService.isMocking {
			AppLog.debug("Using default notification preferences in mock mode", category: "Push")
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
				activityInvitesEnabled = preferences.activityInvitesEnabled
				activityUpdatesEnabled = preferences.activityUpdatesEnabled
				chatMessagesEnabled = preferences.chatMessagesEnabled

				// Save to UserDefaults as fallback
				savePreferencesToUserDefaults()
			} catch let error as APIError {
				// Check if it's a 404 error (endpoint doesn't exist yet)
				if case .invalidStatusCode(let statusCode) = error, statusCode == 404 {
					AppLog.debug(
						"Notification preferences endpoint not available (404): Using UserDefaults values",
						category: "Push")
					// Continue using the UserDefaults values that were loaded in init()
				} else {
					AppLog.warning(
						"Failed to fetch notification preferences: \(error.localizedDescription)", category: "Push")
				}
			} catch {
				AppLog.warning(
					"Failed to fetch notification preferences: \(error.localizedDescription)", category: "Push")
			}
		}
	}

	// Update notification preferences on the backend
	func updateNotificationPreferences() async {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			AppLog.debug("Cannot update notification preferences: user not logged in", category: "Push")
			return
		}

		if let user = UserAuthViewModel.shared.spawnUser {
			AppLog.debug(
				"Updating notification preferences for user ID: \(userId) (username: \(user.username ?? "Unknown"), name: \(user.name ?? "Unknown"))",
				category: "Push"
			)
		}

		// Save to UserDefaults immediately (optimistic update)
		savePreferencesToUserDefaults()

		// Don't update backend if in mock mode
		if MockAPIService.isMocking {
			AppLog.debug("Skipping backend update for notification preferences in mock mode", category: "Push")
			return
		}

		let preferences = NotificationPreferencesDTO(
			friendRequestsEnabled: friendRequestsEnabled,
			activityInvitesEnabled: activityInvitesEnabled,
			activityUpdatesEnabled: activityUpdatesEnabled,
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
					AppLog.debug(
						"Notification preferences endpoint not available (404): Values saved to UserDefaults only",
						category: "Push"
					)
					// We've already saved to UserDefaults above, so just continue
				} else {
					AppLog.warning(
						"Failed to update notification preferences: \(error.localizedDescription)", category: "Push")
				}
			} catch {
				AppLog.warning(
					"Failed to update notification preferences: \(error.localizedDescription)", category: "Push")
			}
		}
	}

	// Note: Notification delegate methods are handled by CustomAppDelegate
	// These methods have been moved there to avoid delegate conflicts

	// Handle notification data and update cache accordingly
	func handleNotificationData(_ userInfo: [AnyHashable: Any]) {
		guard let type = userInfo["type"] as? String else {
			AppLog.debug("Notification missing type", category: "Push")
			return
		}

		// Get the current user ID for DataService calls
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			AppLog.debug("Cannot handle notification - no logged in user", category: "Push")
			return
		}

		Task {
			switch type {
			case "friend-accepted":
				// When a friend request is accepted, refresh friends and friend requests
				let _: DataResult<[FullFriendUserDTO]> = await DataService.shared.read(
					.friends(userId: userId), cachePolicy: .apiOnly)
				let _: DataResult<[FetchFriendRequestDTO]> = await DataService.shared.read(
					.friendRequests(userId: userId), cachePolicy: .apiOnly)
				let _: DataResult<[FetchSentFriendRequestDTO]> = await DataService.shared.read(
					.sentFriendRequests(userId: userId), cachePolicy: .apiOnly)

			case "activity-updated":
				// When an activity is updated, refresh activities
				let _: DataResult<[FullFeedActivityDTO]> = await DataService.shared.read(
					.activities(userId: userId), cachePolicy: .apiOnly)

			case "friend-request":
				// When a new friend request is received/sent, refresh both incoming and sent friend requests
				let _: DataResult<[FetchFriendRequestDTO]> = await DataService.shared.read(
					.friendRequests(userId: userId), cachePolicy: .apiOnly)
				let _: DataResult<[FetchSentFriendRequestDTO]> = await DataService.shared.read(
					.sentFriendRequests(userId: userId), cachePolicy: .apiOnly)

			case "profile-updated":
				// When a friend's profile is updated, refresh other profiles
				if let profileUserId = userInfo["userId"] as? String,
					let uuid = UUID(uuidString: profileUserId)
				{
					// Check if this is a profile we already have cached
					if appCache.otherProfiles[uuid] != nil {
						await appCache.refreshOtherProfiles()
					}
				}

			default:
				AppLog.debug("Unknown notification type: \(type) - triggering full cache validation", category: "Push")
				// For unknown notification types, validate the entire cache
				await appCache.validateCache()
			}
		}
	}

	// Add a method to unregister the device token when signing out
	func unregisterDeviceToken() async {
		guard let token = storedDeviceToken ?? Messaging.messaging().fcmToken else {
			AppLog.debug("No device token to unregister", category: "Push")
			return
		}

		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			AppLog.debug("Cannot unregister token: no user ID available - clearing token locally", category: "Push")
			// Clear the stored token locally since we can't unregister from backend
			storedDeviceToken = nil
			return
		}

		AppLog.debug("Preparing to unregister device token: \(token)", category: "Push")

		if let url = URL(string: "\(APIService.baseURL)notifications/device-tokens") {
			do {
				// Create device token DTO
				let deviceTokenDTO = DeviceTokenDTO(
					token: token,
					deviceType: "IOS",
					userId: userId
				)

				// Send DELETE request with token in body
				try await apiService.deleteData(
					from: url,
					parameters: nil,
					object: deviceTokenDTO
				)

				AppLog.debug("Successfully unregistered device token", category: "Push")
				// Clear the stored token after successful unregistration
				storedDeviceToken = nil
			} catch {
				AppLog.debug("Failed to unregister device token: \(error.localizedDescription)", category: "Push")
				// Clear the stored token locally even if backend unregistration failed
				storedDeviceToken = nil
			}
		}
	}
}

// Extension for handling device token registration
extension NotificationService {
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
		let token = tokenParts.joined()
		AppLog.debug("Device token (APNs): \(token)", category: "Push")

		sendDeviceTokenToServer(token)
	}

	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		AppLog.warning("Failed to register for notifications: \(error.localizedDescription)", category: "Push")
	}

	private func sendDeviceTokenToServer(_ token: String) {
		// Implement to send token to your server
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }

		Task {
			do {
				guard let url = URL(string: APIService.baseURL + "users/\(userId)/device-token") else { return }

				let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()

				let tokenData = ["deviceToken": token]
				_ = try await apiService.patchData(from: url, with: tokenData) as EmptyResponse

				AppLog.debug("Device token successfully sent to server", category: "Push")
			} catch {
				AppLog.warning("Failed to send device token: \(error)", category: "Push")
			}
		}
	}
}
