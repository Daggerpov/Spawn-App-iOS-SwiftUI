import Combine
import SwiftUI

@MainActor
final class InAppNotificationManager: ObservableObject {
	static let shared = InAppNotificationManager()

	@Published var isShowingNotification = false
	@Published var currentNotification: InAppNotificationData?

	private init() {}

	/// Show an in-app notification
	/// - Parameters:
	///   - title: The notification title
	///   - message: The notification message
	///   - type: The notification type
	///   - duration: How long to show the notification (default: 4 seconds)
	/// Track the current auto-dismiss task
	/// - Note: `nonisolated(unsafe)` allows safe access from nonisolated deinit if needed.
	/// This is a singleton so deinit won't be called in practice, but marking it for consistency.
	private nonisolated(unsafe) var dismissTask: Task<Void, Never>?
	private var clearTask: Task<Void, Never>?

	func showNotification(
		title: String,
		message: String,
		type: NotificationType,
		duration: TimeInterval = 4.0
	) {
		print("📱 [InAppNotificationManager] Showing notification: \(title) - Duration: \(duration)s")

		// Cancel any existing dismiss task
		dismissTask?.cancel()
		dismissTask = nil
		// A previous banner may still be finishing its dismissal animation.
		clearTask?.cancel()
		clearTask = nil

		// Set new notification data immediately
		currentNotification = InAppNotificationData(
			title: title,
			message: message,
			type: type
		)

		// Show notification with animation
		withAnimation(.easeInOut(duration: 0.3)) {
			isShowingNotification = true
		}

		print("📱 [InAppNotificationManager] Notification shown, will dismiss in \(duration)s")

		// Auto-dismiss after duration using Task
		dismissTask = Task { [weak self] in
			try? await Task.sleep(for: .seconds(duration))
			guard !Task.isCancelled else { return }
			print("📱 [InAppNotificationManager] Auto-dismissing notification")
			self?.dismissNotification()
		}
	}

	/// Dismiss the current notification
	func dismissNotification() {
		print("📱 [InAppNotificationManager] Dismissing notification")
		dismissTask?.cancel()
		dismissTask = nil
		clearTask?.cancel()

		// Hide notification with animation
		withAnimation(.easeInOut(duration: 0.3)) {
			isShowingNotification = false
		}

		// Clear notification data after animation
		clearTask = Task { [weak self] in
			try? await Task.sleep(for: .seconds(0.3))
			guard !Task.isCancelled else { return }
			self?.currentNotification = nil
		}
	}

	/// Show notification from push notification payload
	/// - Parameter userInfo: The push notification payload
	func showNotificationFromPushData(_ userInfo: [AnyHashable: Any]) {
		guard let typeString = userInfo["type"] as? String,
			let notificationType = NotificationType(pushValue: typeString)
		else {
			print("[IN-APP NOTIFICATION] Invalid notification type in payload")
			return
		}

		// FCM puts the event's actual wording in aps.alert. In particular, an accepted
		// request must retain its acceptance message instead of the new-request fallback.
		let aps = userInfo["aps"] as? [String: Any]
		let alert = aps?["alert"] as? [String: Any]
		let title = alert?["title"] as? String ?? extractTitle(from: userInfo, type: notificationType)
		let message = alert?["body"] as? String
			?? aps?["alert"] as? String
			?? extractMessage(from: userInfo, type: notificationType)

		showNotification(title: title, message: message, type: notificationType)
	}

	// MARK: - Private Helpers

	private func extractTitle(from userInfo: [AnyHashable: Any], type: NotificationType) -> String {
		switch type {
		case .friendRequest:
			return "Friend Request"
		case .activityInvite:
			return "Activity Invite"
		case .activityUpdate:
			return "Activity Update"
		case .chat:
			return "New Message"
		case .welcome:
			return "Welcome!"
		case .error:
			return "Error"
		case .success:
			return "Success"
		}
	}

	private func extractMessage(from userInfo: [AnyHashable: Any], type: NotificationType) -> String {
		switch type {
		case .friendRequest:
			if let senderName = userInfo["senderName"] as? String {
				return "\(senderName) wants to be your friend"
			}
			return "You have a new friend request"

		case .activityInvite:
			if let activityName = userInfo["activityName"] as? String {
				return "You're invited to \(activityName)"
			}
			return "You have a new activity invitation"

		case .activityUpdate:
			if let activityName = userInfo["activityName"] as? String,
				let updateType = userInfo["updateType"] as? String
			{
				return "\(activityName) has been \(updateType)"
			} else if let activityName = userInfo["activityName"] as? String {
				return "\(activityName) has been updated"
			}
			return "An activity has been updated"

		case .chat:
			if let activityName = userInfo["activityName"] as? String,
				let senderName = userInfo["senderName"] as? String
			{
				return "\(senderName) sent a message in \(activityName)"
			} else if let senderName = userInfo["senderName"] as? String {
				return "\(senderName) sent you a message"
			}
			return "You have a new message"

		case .welcome:
			return "Welcome to Spawn! Start connecting with friends."

		case .error:
			if let errorMessage = userInfo["errorMessage"] as? String {
				return errorMessage
			}
			return "Something went wrong. Please try again."

		case .success:
			if let successMessage = userInfo["successMessage"] as? String {
				return successMessage
			}
			return "Action completed successfully"
		}
	}
}

// MARK: - Data Model

struct InAppNotificationData {
	let title: String
	let message: String
	let type: NotificationType
}
