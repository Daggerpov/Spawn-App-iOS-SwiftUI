//
//  ErrorNotificationService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 2025-01-27.
//

import Foundation

/// Context about the resource being operated on when an error occurs
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
	case generic = "request"

	/// Plural form for display
	var displayName: String {
		return rawValue
	}

	/// Article to use ("a" or "an")
	var article: String {
		switch self {
		case .activity, .activities, .activityType, .account:
			return "an"
		default:
			return "a"
		}
	}
}

/// The type of operation being performed when an error occurs
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
		case .generic:
			return "action"
		}
	}
}

/// Centralized service for displaying error notifications to users
/// Filters out non-user-facing errors (like cancellations) and formats errors appropriately
@MainActor
final class ErrorNotificationService {
	static let shared = ErrorNotificationService()

	private let errorFormattingService = ErrorFormattingService.shared
	private let notificationManager = InAppNotificationManager.shared

	private init() {}

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
			print("📱 [ErrorNotificationService] Skipping notification for cancelled request")
			return
		}

		let title = customTitle ?? generateTitle(resource: resource, operation: operation)
		let message = generateMessage(error: error, resource: resource, operation: operation)

		print(
			"📱 [ErrorNotificationService] Showing error: \(title) - \(message) [resource: \(resource.rawValue), operation: \(operation.rawValue)]"
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
			print("📱 [ErrorNotificationService] Skipping notification for cancelled request")
			return
		}

		let message = errorFormattingService.formatError(error)

		print("📱 [ErrorNotificationService] Showing error: \(title) - \(message)")

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
		print("📱 [ErrorNotificationService] Showing error message: \(title) - \(message)")

		notificationManager.showNotification(
			title: title,
			message: message,
			type: .error,
			duration: duration
		)
	}

	/// Show a success notification
	/// - Parameters:
	///   - message: The success message to display
	///   - title: The notification title (defaults to "Success")
	///   - duration: How long to show the notification (default: 3 seconds)
	func showSuccess(
		_ message: String,
		title: String = "Success",
		duration: TimeInterval = 3.0
	) {
		print("📱 [ErrorNotificationService] Showing success: \(title) - \(message)")

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
		case .delete:
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
		default:
			return "This \(resource.displayName) already exists or conflicts with another."
		}
	}
}

// MARK: - Convenience extension for ViewModels
extension ErrorNotificationService {

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
