//
//  InAppNotificationService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 2025-01-27.
//

import Foundation

/// Context about the resource being operated on when a notification occurs
enum ResourceContext: String, Sendable {
	case activity = "activity"
	case activities = "activities"
	case friend = "friend"
	case friends = "friends"
	case friendRequest = "friend request"
	case tag = "tag"
	case tags = "tags"
	case profile = "profile"
	case profilePicture = "profile picture"
	case user = "user"
	case message = "message"
	case chat = "chat"
	case activityType = "activity type"
	case report = "report"
	case blockedUser = "blocked user"
	case notification = "notification"
	case location = "location"
	case feedback = "feedback"
	case calendar = "calendar"
	case contacts = "contacts"
	case password = "password"
	case account = "account"
	case settings = "settings"
	case preferences = "preferences"
	case invite = "invite"
	case participant = "participant"
	case generic = "request"

	/// Plural form for display
	var displayName: String {
		return rawValue
	}

	/// Article to use ("a" or "an")
	var article: String {
		switch self {
		case .activity, .activities, .activityType, .account, .invite:
			return "an"
		default:
			return "a"
		}
	}
}

/// The type of operation being performed when a notification occurs
enum OperationContext: String, Sendable {
	case create = "create"
	case fetch = "load"
	case update = "update"
	case delete = "delete"
	case join = "join"
	case leave = "leave"
	case send = "send"
	case accept = "accept"
	case reject = "reject"
	case block = "block"
	case unblock = "unblock"
	case report = "report"
	case upload = "upload"
	case download = "download"
	case verify = "verify"
	case save = "save"
	case refresh = "refresh"
	case search = "search"
	case invite = "invite"
	case remove = "remove"
	case add = "add"
	case cancel = "cancel"
	case copy = "copy"
	case share = "share"
	case sync = "sync"
	case import_ = "import"
	case export = "export"
	case enable = "enable"
	case disable = "disable"
	case reset = "reset"
	case generic = "complete"

	/// Past tense for display
	var pastTense: String {
		switch self {
		case .create:
			return "creating"
		case .fetch:
			return "loading"
		case .update:
			return "updating"
		case .delete:
			return "deleting"
		case .join:
			return "joining"
		case .leave:
			return "leaving"
		case .send:
			return "sending"
		case .accept:
			return "accepting"
		case .reject:
			return "rejecting"
		case .block:
			return "blocking"
		case .unblock:
			return "unblocking"
		case .report:
			return "reporting"
		case .upload:
			return "uploading"
		case .download:
			return "downloading"
		case .verify:
			return "verifying"
		case .save:
			return "saving"
		case .refresh:
			return "refreshing"
		case .search:
			return "searching"
		case .invite:
			return "inviting"
		case .remove:
			return "removing"
		case .add:
			return "adding"
		case .cancel:
			return "cancelling"
		case .copy:
			return "copying"
		case .share:
			return "sharing"
		case .sync:
			return "syncing"
		case .import_:
			return "importing"
		case .export:
			return "exporting"
		case .enable:
			return "enabling"
		case .disable:
			return "disabling"
		case .reset:
			return "resetting"
		case .generic:
			return "completing"
		}
	}

	/// Noun form for display (e.g., "creation failed")
	var nounForm: String {
		switch self {
		case .create:
			return "creation"
		case .fetch:
			return "loading"
		case .update:
			return "update"
		case .delete:
			return "deletion"
		case .join:
			return "join"
		case .leave:
			return "leave"
		case .send:
			return "send"
		case .accept:
			return "acceptance"
		case .reject:
			return "rejection"
		case .block:
			return "block"
		case .unblock:
			return "unblock"
		case .report:
			return "report"
		case .upload:
			return "upload"
		case .download:
			return "download"
		case .verify:
			return "verification"
		case .save:
			return "save"
		case .refresh:
			return "refresh"
		case .search:
			return "search"
		case .invite:
			return "invitation"
		case .remove:
			return "removal"
		case .add:
			return "addition"
		case .cancel:
			return "cancellation"
		case .copy:
			return "copy"
		case .share:
			return "share"
		case .sync:
			return "sync"
		case .import_:
			return "import"
		case .export:
			return "export"
		case .enable:
			return "enablement"
		case .disable:
			return "disablement"
		case .reset:
			return "reset"
		case .generic:
			return "action"
		}
	}
}

/// Specific success scenarios for extensible success notifications
/// Use these for common success patterns, or use ResourceContext + OperationContext for custom combinations
enum SuccessType: Sendable {
	// MARK: - Friend-related successes
	case friendRequestSent
	case friendRequestAccepted
	case friendRequestDeclined
	case friendRemoved
	case friendAdded

	// MARK: - Activity-related successes
	case activityCreated
	case activityUpdated
	case activityDeleted
	case activityJoined
	case activityLeft
	case activityCancelled
	case activityInviteSent

	// MARK: - Activity Type successes
	case activityTypeCreated
	case activityTypeUpdated
	case activityTypeDeleted

	// MARK: - Profile-related successes
	case profileUpdated
	case profilePictureUploaded
	case profilePictureRemoved
	case passwordChanged
	case accountDeleted

	// MARK: - User interaction successes
	case userBlocked
	case userUnblocked
	case userReported

	// MARK: - Message-related successes
	case messageSent
	case chatCleared

	// MARK: - Feedback successes
	case feedbackSent
	case reportSubmitted

	// MARK: - Tag-related successes
	case tagCreated
	case tagUpdated
	case tagDeleted
	case tagAssigned
	case tagRemoved

	// MARK: - Settings-related successes
	case settingsSaved
	case preferencesSaved
	case notificationsEnabled
	case notificationsDisabled

	// MARK: - Data management successes
	case dataSynced
	case dataExported
	case dataImported
	case cacheCleared

	// MARK: - Invite-related successes
	case inviteSent
	case inviteAccepted
	case inviteDeclined
	case inviteCancelled

	// MARK: - Copy/Share successes
	case linkCopied
	case contentShared

	// MARK: - Generic successes
	case actionCompleted
	case custom(title: String, message: String)

	/// The title for this success type
	var title: String {
		switch self {
		// Friend-related
		case .friendRequestSent:
			return "Request Sent"
		case .friendRequestAccepted:
			return "Friend Added"
		case .friendRequestDeclined:
			return "Request Declined"
		case .friendRemoved:
			return "Friend Removed"
		case .friendAdded:
			return "Friend Added"

		// Activity-related
		case .activityCreated:
			return "Activity Created"
		case .activityUpdated:
			return "Activity Updated"
		case .activityDeleted:
			return "Activity Deleted"
		case .activityJoined:
			return "Joined Activity"
		case .activityLeft:
			return "Left Activity"
		case .activityCancelled:
			return "Activity Cancelled"
		case .activityInviteSent:
			return "Invite Sent"

		// Activity Type
		case .activityTypeCreated:
			return "Activity Type Created"
		case .activityTypeUpdated:
			return "Activity Type Updated"
		case .activityTypeDeleted:
			return "Activity Type Deleted"

		// Profile-related
		case .profileUpdated:
			return "Profile Updated"
		case .profilePictureUploaded:
			return "Photo Updated"
		case .profilePictureRemoved:
			return "Photo Removed"
		case .passwordChanged:
			return "Password Changed"
		case .accountDeleted:
			return "Account Deleted"

		// User interaction
		case .userBlocked:
			return "User Blocked"
		case .userUnblocked:
			return "User Unblocked"
		case .userReported:
			return "Report Submitted"

		// Message-related
		case .messageSent:
			return "Message Sent"
		case .chatCleared:
			return "Chat Cleared"

		// Feedback
		case .feedbackSent:
			return "Feedback Sent"
		case .reportSubmitted:
			return "Report Submitted"

		// Tag-related
		case .tagCreated:
			return "Tag Created"
		case .tagUpdated:
			return "Tag Updated"
		case .tagDeleted:
			return "Tag Deleted"
		case .tagAssigned:
			return "Tag Assigned"
		case .tagRemoved:
			return "Tag Removed"

		// Settings-related
		case .settingsSaved:
			return "Settings Saved"
		case .preferencesSaved:
			return "Preferences Saved"
		case .notificationsEnabled:
			return "Notifications Enabled"
		case .notificationsDisabled:
			return "Notifications Disabled"

		// Data management
		case .dataSynced:
			return "Data Synced"
		case .dataExported:
			return "Data Exported"
		case .dataImported:
			return "Data Imported"
		case .cacheCleared:
			return "Cache Cleared"

		// Invite-related
		case .inviteSent:
			return "Invite Sent"
		case .inviteAccepted:
			return "Invite Accepted"
		case .inviteDeclined:
			return "Invite Declined"
		case .inviteCancelled:
			return "Invite Cancelled"

		// Copy/Share
		case .linkCopied:
			return "Link Copied"
		case .contentShared:
			return "Shared"

		// Generic
		case .actionCompleted:
			return "Success"
		case .custom(let title, _):
			return title
		}
	}

	/// The message for this success type
	var message: String {
		switch self {
		// Friend-related
		case .friendRequestSent:
			return "Your friend request has been sent successfully."
		case .friendRequestAccepted:
			return "You are now friends!"
		case .friendRequestDeclined:
			return "Friend request has been declined."
		case .friendRemoved:
			return "Friend has been removed from your list."
		case .friendAdded:
			return "Friend has been added to your list."

		// Activity-related
		case .activityCreated:
			return "Your activity has been created."
		case .activityUpdated:
			return "Activity has been updated."
		case .activityDeleted:
			return "Activity has been deleted."
		case .activityJoined:
			return "You've joined the activity!"
		case .activityLeft:
			return "You've left the activity."
		case .activityCancelled:
			return "Activity has been cancelled."
		case .activityInviteSent:
			return "Invitations have been sent."

		// Activity Type
		case .activityTypeCreated:
			return "Activity type has been created."
		case .activityTypeUpdated:
			return "Activity type has been updated."
		case .activityTypeDeleted:
			return "Activity type has been deleted."

		// Profile-related
		case .profileUpdated:
			return "Your profile has been updated."
		case .profilePictureUploaded:
			return "Profile picture has been updated."
		case .profilePictureRemoved:
			return "Profile picture has been removed."
		case .passwordChanged:
			return "Your password has been changed successfully."
		case .accountDeleted:
			return "Your account has been deleted."

		// User interaction
		case .userBlocked:
			return "User has been blocked."
		case .userUnblocked:
			return "User has been unblocked."
		case .userReported:
			return "Thank you for your report. We'll review it shortly."

		// Message-related
		case .messageSent:
			return "Message sent."
		case .chatCleared:
			return "Chat history has been cleared."

		// Feedback
		case .feedbackSent:
			return "Thank you for your feedback!"
		case .reportSubmitted:
			return "Thank you for your report. We'll review it shortly."

		// Tag-related
		case .tagCreated:
			return "Tag has been created."
		case .tagUpdated:
			return "Tag has been updated."
		case .tagDeleted:
			return "Tag has been deleted."
		case .tagAssigned:
			return "Tag has been assigned."
		case .tagRemoved:
			return "Tag has been removed."

		// Settings-related
		case .settingsSaved:
			return "Your settings have been saved."
		case .preferencesSaved:
			return "Your preferences have been saved."
		case .notificationsEnabled:
			return "Notifications have been enabled."
		case .notificationsDisabled:
			return "Notifications have been disabled."

		// Data management
		case .dataSynced:
			return "Your data has been synced."
		case .dataExported:
			return "Your data has been exported."
		case .dataImported:
			return "Your data has been imported."
		case .cacheCleared:
			return "Cache has been cleared."

		// Invite-related
		case .inviteSent:
			return "Invitation has been sent."
		case .inviteAccepted:
			return "Invitation accepted."
		case .inviteDeclined:
			return "Invitation declined."
		case .inviteCancelled:
			return "Invitation has been cancelled."

		// Copy/Share
		case .linkCopied:
			return "Link copied to clipboard."
		case .contentShared:
			return "Content has been shared."

		// Generic
		case .actionCompleted:
			return "Action completed successfully."
		case .custom(_, let message):
			return message
		}
	}
}

/// Centralized service for displaying user notifications (errors and success feedback)
/// Filters out non-user-facing errors (like cancellations) and formats messages appropriately
@MainActor
final class InAppNotificationService {
	static let shared = InAppNotificationService()

	private let errorFormattingService = ErrorFormattingService.shared
	private let notificationManager = InAppNotificationManager.shared

	private init() {}

	// MARK: - Success Notifications with SuccessType

	/// Show a success notification using a predefined success type
	/// - Parameters:
	///   - type: The type of success to display
	///   - duration: How long to show the notification (default: 3 seconds)
	func showSuccess(
		_ type: SuccessType,
		duration: TimeInterval = 3.0
	) {
		print(
			"📱 [InAppNotificationService] Showing success: \(type.title) - \(type.message)"
		)

		notificationManager.showNotification(
			title: type.title,
			message: type.message,
			type: .success,
			duration: duration
		)
	}

	// MARK: - Success Notifications with Context

	/// Show a success notification with resource and operation context
	/// - Parameters:
	///   - resource: The type of resource that was operated on
	///   - operation: The type of operation that succeeded
	///   - customTitle: Optional custom title (defaults to contextual title)
	///   - customMessage: Optional custom message (defaults to contextual message)
	///   - duration: How long to show the notification (default: 3 seconds)
	func showSuccess(
		resource: ResourceContext,
		operation: OperationContext,
		customTitle: String? = nil,
		customMessage: String? = nil,
		duration: TimeInterval = 3.0
	) {
		let title = customTitle ?? generateSuccessTitle(resource: resource, operation: operation)
		let message = customMessage ?? generateSuccessMessage(resource: resource, operation: operation)

		print(
			"📱 [InAppNotificationService] Showing success: \(title) - \(message) [resource: \(resource.rawValue), operation: \(operation.rawValue)]"
		)

		notificationManager.showNotification(
			title: title,
			message: message,
			type: .success,
			duration: duration
		)
	}

	/// Generate a contextual title for success notifications
	private func generateSuccessTitle(resource: ResourceContext, operation: OperationContext) -> String {
		// Capitalize first letter of resource
		let resourceName = resource.displayName.prefix(1).uppercased() + resource.displayName.dropFirst()

		switch operation {
		case .send:
			return "\(resourceName) Sent"
		case .create:
			return "\(resourceName) Created"
		case .update, .save:
			return "\(resourceName) Updated"
		case .delete, .remove:
			return "\(resourceName) Removed"
		case .accept:
			return "\(resourceName) Accepted"
		case .reject:
			return "\(resourceName) Declined"
		case .join:
			return "Joined \(resourceName)"
		case .leave:
			return "Left \(resourceName)"
		case .block:
			return "User Blocked"
		case .unblock:
			return "User Unblocked"
		case .report:
			return "Report Submitted"
		case .upload:
			return "\(resourceName) Uploaded"
		case .download:
			return "\(resourceName) Downloaded"
		case .verify:
			return "Verified"
		case .fetch, .refresh:
			return "\(resourceName) Loaded"
		case .search:
			return "Search Complete"
		case .invite:
			return "\(resourceName) Invited"
		case .add:
			return "\(resourceName) Added"
		case .cancel:
			return "\(resourceName) Cancelled"
		case .copy:
			return "\(resourceName) Copied"
		case .share:
			return "\(resourceName) Shared"
		case .sync:
			return "\(resourceName) Synced"
		case .import_:
			return "\(resourceName) Imported"
		case .export:
			return "\(resourceName) Exported"
		case .enable:
			return "\(resourceName) Enabled"
		case .disable:
			return "\(resourceName) Disabled"
		case .reset:
			return "\(resourceName) Reset"
		case .generic:
			return "Success"
		}
	}

	/// Generate a contextual message for success notifications
	private func generateSuccessMessage(resource: ResourceContext, operation: OperationContext) -> String {
		switch (resource, operation) {
		// Friend-related
		case (.friendRequest, .send):
			return "Your friend request has been sent successfully."
		case (.friendRequest, .accept):
			return "You are now friends!"
		case (.friendRequest, .reject):
			return "Friend request has been declined."
		case (.friend, .delete), (.friend, .remove):
			return "Friend has been removed from your list."
		case (.friend, .add):
			return "Friend has been added to your list."

		// Activity-related
		case (.activity, .create):
			return "Your activity has been created."
		case (.activity, .update):
			return "Activity has been updated."
		case (.activity, .delete):
			return "Activity has been deleted."
		case (.activity, .join):
			return "You've joined the activity!"
		case (.activity, .leave):
			return "You've left the activity."
		case (.activity, .cancel):
			return "Activity has been cancelled."

		// Activity Type-related
		case (.activityType, .create):
			return "Activity type has been created."
		case (.activityType, .update):
			return "Activity type has been updated."
		case (.activityType, .delete):
			return "Activity type has been deleted."

		// Profile-related
		case (.profile, .update), (.profile, .save):
			return "Your profile has been updated."
		case (.profilePicture, .upload):
			return "Profile picture has been updated."
		case (.profilePicture, .delete), (.profilePicture, .remove):
			return "Profile picture has been removed."
		case (.password, .update), (.password, .reset):
			return "Your password has been changed successfully."
		case (.account, .delete):
			return "Your account has been deleted."

		// User interaction
		case (.user, .block):
			return "User has been blocked."
		case (.user, .unblock):
			return "User has been unblocked."
		case (.user, .report):
			return "Thank you for your report. We'll review it shortly."
		case (.blockedUser, .delete), (.blockedUser, .remove):
			return "User has been unblocked."

		// Message-related
		case (.message, .send):
			return "Message sent."
		case (.chat, .delete):
			return "Chat history has been cleared."

		// Feedback
		case (.feedback, .send):
			return "Thank you for your feedback!"
		case (.report, .send), (.report, .create):
			return "Thank you for your report. We'll review it shortly."

		// Tag-related
		case (.tag, .create):
			return "Tag has been created."
		case (.tag, .update):
			return "Tag has been updated."
		case (.tag, .delete):
			return "Tag has been deleted."
		case (.tag, .add):
			return "Tag has been assigned."
		case (.tag, .remove):
			return "Tag has been removed."

		// Settings-related
		case (.settings, .save), (.settings, .update):
			return "Your settings have been saved."
		case (.preferences, .save), (.preferences, .update):
			return "Your preferences have been saved."
		case (.notification, .enable):
			return "Notifications have been enabled."
		case (.notification, .disable):
			return "Notifications have been disabled."

		// Invite-related
		case (.invite, .send):
			return "Invitation has been sent."
		case (.invite, .accept):
			return "Invitation accepted."
		case (.invite, .reject):
			return "Invitation declined."
		case (.invite, .cancel):
			return "Invitation has been cancelled."

		// Participant-related
		case (.participant, .add):
			return "Participant has been added."
		case (.participant, .remove):
			return "Participant has been removed."
		case (.participant, .invite):
			return "Invitation has been sent."

		// Calendar/Contacts
		case (.calendar, .sync):
			return "Calendar has been synced."
		case (.contacts, .sync):
			return "Contacts have been synced."
		case (.contacts, .import_):
			return "Contacts have been imported."

		// Default fallback - generates a sensible message for any combination
		default:
			return generateDefaultSuccessMessage(resource: resource, operation: operation)
		}
	}

	/// Generate a default success message for combinations not explicitly handled
	private func generateDefaultSuccessMessage(resource: ResourceContext, operation: OperationContext) -> String {
		let resourceName = resource.displayName
		let article = resource.article

		switch operation {
		case .create:
			return "The \(resourceName) has been created."
		case .update, .save:
			return "The \(resourceName) has been updated."
		case .delete, .remove:
			return "The \(resourceName) has been removed."
		case .send:
			return "The \(resourceName) has been sent."
		case .fetch, .refresh:
			return "The \(resourceName) has been loaded."
		case .accept:
			return "The \(resourceName) has been accepted."
		case .reject:
			return "The \(resourceName) has been declined."
		case .join:
			return "You have joined the \(resourceName)."
		case .leave:
			return "You have left the \(resourceName)."
		case .block:
			return "The \(resourceName) has been blocked."
		case .unblock:
			return "The \(resourceName) has been unblocked."
		case .report:
			return "The \(resourceName) has been reported."
		case .upload:
			return "The \(resourceName) has been uploaded."
		case .download:
			return "The \(resourceName) has been downloaded."
		case .verify:
			return "The \(resourceName) has been verified."
		case .search:
			return "Search completed."
		case .invite:
			return "The \(resourceName) has been invited."
		case .add:
			return "The \(resourceName) has been added."
		case .cancel:
			return "The \(resourceName) has been cancelled."
		case .copy:
			return "The \(resourceName) has been copied."
		case .share:
			return "The \(resourceName) has been shared."
		case .sync:
			return "The \(resourceName) has been synced."
		case .import_:
			return "The \(resourceName) has been imported."
		case .export:
			return "The \(resourceName) has been exported."
		case .enable:
			return "The \(resourceName) has been enabled."
		case .disable:
			return "The \(resourceName) has been disabled."
		case .reset:
			return "The \(resourceName) has been reset."
		case .generic:
			return "Action completed successfully."
		}
	}

	/// Show an error notification with resource and operation context
	/// - Parameters:
	///   - error: The error that occurred
	///   - resource: The type of resource being operated on
	///   - operation: The type of operation that failed
	///   - customTitle: Optional custom title (defaults to contextual title)
	///   - duration: How long to show the notification (default: 4 seconds)
	func showError(
		_ error: Error,
		resource: ResourceContext = .generic,
		operation: OperationContext = .generic,
		customTitle: String? = nil,
		duration: TimeInterval = 4.0
	) {
		// Don't show notifications for cancelled requests - these are expected behavior
		if APIError.isCancellation(error) {
			print("📱 [InAppNotificationService] Skipping notification for cancelled request")
			return
		}

		let title = customTitle ?? generateTitle(resource: resource, operation: operation)
		let message = generateMessage(error: error, resource: resource, operation: operation)

		print(
			"📱 [InAppNotificationService] Showing error: \(title) - \(message) [resource: \(resource.rawValue), operation: \(operation.rawValue)]"
		)

		notificationManager.showNotification(
			title: title,
			message: message,
			type: .error,
			duration: duration
		)
	}

	/// Show a simple error notification without context
	/// - Parameters:
	///   - error: The error that occurred
	///   - title: The notification title
	///   - duration: How long to show the notification (default: 4 seconds)
	func showError(
		_ error: Error,
		title: String = "Error",
		duration: TimeInterval = 4.0
	) {
		// Don't show notifications for cancelled requests
		if APIError.isCancellation(error) {
			print("📱 [InAppNotificationService] Skipping notification for cancelled request")
			return
		}

		let message = errorFormattingService.formatError(error)

		print("📱 [InAppNotificationService] Showing error: \(title) - \(message)")

		notificationManager.showNotification(
			title: title,
			message: message,
			type: .error,
			duration: duration
		)
	}

	/// Show an error notification with a pre-formatted message
	/// - Parameters:
	///   - message: The error message to display
	///   - title: The notification title
	///   - duration: How long to show the notification (default: 4 seconds)
	func showErrorMessage(
		_ message: String,
		title: String = "Error",
		duration: TimeInterval = 4.0
	) {
		print("📱 [InAppNotificationService] Showing error message: \(title) - \(message)")

		notificationManager.showNotification(
			title: title,
			message: message,
			type: .error,
			duration: duration
		)
	}

	/// Show a success notification with a simple message
	/// - Parameters:
	///   - message: The success message to display
	///   - title: The notification title (defaults to "Success")
	///   - duration: How long to show the notification (default: 3 seconds)
	func showSuccess(
		_ message: String,
		title: String = "Success",
		duration: TimeInterval = 3.0
	) {
		print("📱 [InAppNotificationService] Showing success: \(title) - \(message)")

		notificationManager.showNotification(
			title: title,
			message: message,
			type: .success,
			duration: duration
		)
	}

	// MARK: - Private Helpers

	/// Generate a contextual title based on the resource and operation
	private func generateTitle(resource: ResourceContext, operation: OperationContext) -> String {
		// Capitalize first letter of resource
		let resourceName = resource.displayName.prefix(1).uppercased() + resource.displayName.dropFirst()

		switch operation {
		case .fetch, .refresh:
			return "Couldn't Load \(resourceName)"
		case .create:
			return "\(resourceName) Creation Failed"
		case .update, .save:
			return "\(resourceName) Update Failed"
		case .delete, .remove:
			return "\(resourceName) Deletion Failed"
		case .join:
			return "Couldn't Join \(resourceName)"
		case .leave:
			return "Couldn't Leave \(resourceName)"
		case .send:
			return "\(resourceName) Not Sent"
		case .accept:
			return "Couldn't Accept \(resourceName)"
		case .reject:
			return "Couldn't Reject \(resourceName)"
		case .block:
			return "Couldn't Block User"
		case .unblock:
			return "Couldn't Unblock User"
		case .report:
			return "Report Failed"
		case .upload:
			return "\(resourceName) Upload Failed"
		case .download:
			return "\(resourceName) Download Failed"
		case .verify:
			return "Verification Failed"
		case .search:
			return "Search Failed"
		case .invite:
			return "Couldn't Send Invite"
		case .add:
			return "Couldn't Add \(resourceName)"
		case .cancel:
			return "Couldn't Cancel \(resourceName)"
		case .copy:
			return "Couldn't Copy \(resourceName)"
		case .share:
			return "Couldn't Share \(resourceName)"
		case .sync:
			return "\(resourceName) Sync Failed"
		case .import_:
			return "\(resourceName) Import Failed"
		case .export:
			return "\(resourceName) Export Failed"
		case .enable:
			return "Couldn't Enable \(resourceName)"
		case .disable:
			return "Couldn't Disable \(resourceName)"
		case .reset:
			return "Couldn't Reset \(resourceName)"
		case .generic:
			return "Something Went Wrong"
		}
	}

	/// Generate a contextual message based on the error, resource, and operation
	private func generateMessage(error: Error, resource: ResourceContext, operation: OperationContext) -> String {
		// First, get the base message from the error
		let baseMessage = errorFormattingService.formatError(error)

		// For specific status codes, provide more context-aware messages
		if let apiError = error as? APIError {
			switch apiError {
			case .invalidStatusCode(let statusCode):
				return generateStatusCodeMessage(
					statusCode: statusCode, resource: resource, operation: operation)
			case .failedHTTPRequest:
				return "We're having trouble connecting. Please check your internet and try again."
			case .cancelled:
				return "Request was cancelled."  // This shouldn't be shown, but just in case
			default:
				return baseMessage
			}
		}

		return baseMessage
	}

	/// Generate a context-aware message based on HTTP status code
	private func generateStatusCodeMessage(statusCode: Int, resource: ResourceContext, operation: OperationContext)
		-> String
	{
		switch statusCode {
		case 400:
			return "Please check your information and try again."

		case 401:
			return "Your session has expired. Please sign in again."

		case 403:
			return "You don't have permission to \(operation.rawValue) this \(resource.displayName)."

		case 404:
			return resourceNotFoundMessage(resource: resource, operation: operation)

		case 409:
			return conflictMessage(resource: resource, operation: operation)

		case 429:
			return "Too many attempts. Please wait a moment and try again."

		case 500...599:
			return "We're experiencing technical difficulties. Please try again shortly."

		default:
			return "We couldn't \(operation.rawValue) the \(resource.displayName). Please try again."
		}
	}

	/// Generate a message for 404 Not Found errors
	private func resourceNotFoundMessage(resource: ResourceContext, operation: OperationContext) -> String {
		switch resource {
		case .activity:
			return "This activity no longer exists or has been cancelled."
		case .friend, .user:
			return "This user could not be found. They may have deleted their account."
		case .friendRequest:
			return "This friend request is no longer available."
		case .tag:
			return "This tag could not be found."
		case .activityType:
			return "This activity type no longer exists."
		case .message, .chat:
			return "This conversation could not be found."
		case .report:
			return "This report could not be found."
		case .blockedUser:
			return "This user is not in your blocked list."
		case .invite:
			return "This invitation could not be found."
		case .participant:
			return "This participant could not be found."
		default:
			return "The requested \(resource.displayName) could not be found."
		}
	}

	/// Generate a message for 409 Conflict errors
	private func conflictMessage(resource: ResourceContext, operation: OperationContext) -> String {
		switch (resource, operation) {
		case (.friendRequest, .send):
			return "A friend request already exists with this user."
		case (.friendRequest, .accept):
			return "This friend request has already been processed."
		case (.activity, .join):
			return "You're already a participant in this activity."
		case (.activity, .create):
			return "An activity with similar details already exists."
		case (.tag, .create):
			return "A tag with this name already exists."
		case (.activityType, .create):
			return "An activity type with this name already exists."
		case (.blockedUser, .block):
			return "This user is already blocked."
		case (.profile, .update), (.user, .update):
			return "This username or information is already in use."
		case (.invite, .send):
			return "This user has already been invited."
		case (.participant, .add):
			return "This user is already a participant."
		default:
			return "This \(resource.displayName) already exists or conflicts with another."
		}
	}
}

// MARK: - Convenience extension for ViewModels
extension InAppNotificationService {

	/// Handle an error from a ViewModel catch block
	/// Returns the formatted error message for ViewModels that also need to store it locally
	@discardableResult
	func handleError(
		_ error: Error,
		resource: ResourceContext = .generic,
		operation: OperationContext = .generic,
		showNotification: Bool = true
	) -> String {
		let message = errorFormattingService.formatError(error)

		if showNotification {
			showError(error, resource: resource, operation: operation)
		}

		return message
	}
}

// MARK: - Type alias for backward compatibility
typealias ErrorNotificationService = InAppNotificationService
