import Foundation

/// Data transfer object for managing notification preferences
struct NotificationPreferencesDTO: Codable, Sendable {
	/// Whether the user wants to receive friend request notifications
	let friendRequestsEnabled: Bool

	/// Whether the user wants to receive activity invite notifications
	let activityInvitesEnabled: Bool

	/// Whether the user wants to receive activity update notifications
	let activityUpdatesEnabled: Bool

	/// Whether the user wants to receive chat message notifications
	let chatMessagesEnabled: Bool

	/// The user ID associated with these preferences
	let userId: UUID
}
