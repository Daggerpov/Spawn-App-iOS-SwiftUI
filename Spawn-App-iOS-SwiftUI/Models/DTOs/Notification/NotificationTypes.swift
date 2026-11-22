import Foundation

/// Defines all notification types used in the app
enum NotificationType: String, Codable, Sendable {
	/// Friend request notifications
	case friendRequest = "friendRequest"

	/// Activity invite notifications
	case activityInvite = "activityInvite"

	/// Activity update notifications
	case activityUpdate = "activityUpdate"

	/// Chat message notifications
	case chat = "chat"

	/// Welcome notification
	case welcome = "welcome"

	/// Error notifications
	case error = "error"

	/// Success notifications
	case success = "success"

	/// Classify server push payloads while preserving the existing local notification values.
	init?(pushValue: String) {
		if let localType = Self(rawValue: pushValue) {
			self = localType
			return
		}

		switch pushValue {
		case "friend-request", "friend_request", "friend-accepted", "friend_request_accepted":
			self = .friendRequest
		case "activity_invite":
			self = .activityInvite
		case "activity_update", "activity_participation", "activity_participation_revoked":
			self = .activityUpdate
		case "new_comment":
			self = .chat
		case "registration", "push_enabled", "push_registration":
			self = .welcome
		default:
			return nil
		}
	}
}

/// Utility for building notification data
struct NotificationDataBuilder: Sendable {
	/// Build notification data for a friend request
	static func friendRequest(senderId: UUID, requestId: UUID) -> [String: String] {
		return [
			"type": NotificationType.friendRequest.rawValue,
			"senderId": senderId.uuidString,
			"requestId": requestId.uuidString,
		]
	}

	/// Build notification data for an activity invite
	static func activityInvite(activityId: UUID, activityName: String) -> [String: String] {
		return [
			"type": NotificationType.activityInvite.rawValue,
			"activityId": activityId.uuidString,
			"activityName": activityName,
		]
	}

	/// Build notification data for an activity update
	static func activityUpdate(activityId: UUID, updateType: String) -> [String: String] {
		return [
			"type": NotificationType.activityUpdate.rawValue,
			"activityId": activityId.uuidString,
			"updateType": updateType,
		]
	}

	/// Build notification data for a chat message
	static func chatMessage(activityId: UUID, senderId: UUID) -> [String: String] {
		return [
			"type": NotificationType.chat.rawValue,
			"activityId": activityId.uuidString,
			"senderId": senderId.uuidString,
		]
	}

	/// Build notification data for a welcome message
	static func welcome() -> [String: String] {
		return [
			"type": NotificationType.welcome.rawValue
		]
	}
}
