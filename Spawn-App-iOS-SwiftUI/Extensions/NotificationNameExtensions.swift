import Foundation

extension Notification.Name {
	// Notification sent when user successfully logs in
	static let userDidLogin = Notification.Name("userDidLogin")

	// Notification sent when user logs out
	static let userDidLogout = Notification.Name("userDidLogout")

	// Notification for activity creation
	static let activityCreated = Notification.Name("activityCreated")

	// Notification for activity updates
	static let activityUpdated = Notification.Name("activityUpdated")

	// Notification for activity deletion
	static let activityDeleted = Notification.Name("activityDeleted")

	// Notification for activity type changes (pin/unpin, edit, create, delete)
	static let activityTypesChanged = Notification.Name("activityTypesChanged")

	// Notification for profile updates (name, username, profile picture)
	static let profileUpdated = Notification.Name("profileUpdated")

	static let refreshUI = Notification.Name("refreshUI")
	static let showChatroom = Notification.Name("showChatroom")
	static let showParticipants = Notification.Name("showParticipants")

	// Global activity popup notification
	static let showGlobalActivityPopup = Notification.Name("showGlobalActivityPopup")

	// Friend system notifications
	static let friendRequestsDidChange = Notification.Name("friendRequestsDidChange")
	static let friendsDidChange = Notification.Name("friendsDidChange")

	// Activity refresh notifications
	static let shouldRefreshActivities = Notification.Name("shouldRefreshActivities")
}
