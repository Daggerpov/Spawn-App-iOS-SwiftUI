//
//  WriteOperationConfig.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-25.
//
//  Configuration for write operations (POST, PUT, PATCH, DELETE).
//  This file centralizes all write operation definitions, making it easy to
//  add new operations or modify existing ones. Pairs with ReadOperationConfig.swift for reads.
//

import Foundation

// MARK: - Write Operation Type Enum

/// Enum representing all write operations that can be performed via DataService
/// Each case includes endpoint, method, and cache invalidation keys
enum WriteOperationType {

	// MARK: - Profile Operations

	/// Add an interest to a user's profile
	case addProfileInterest(userId: UUID, interest: String)

	/// Remove an interest from a user's profile
	case removeProfileInterest(userId: UUID, interest: String)

	/// Update user's social media links
	case updateSocialMedia(userId: UUID, socialMedia: UpdateUserSocialMediaDTO)

	// MARK: - Friend Operations

	/// Send a friend request
	case sendFriendRequest(request: CreateFriendRequestDTO)

	/// Accept a friend request
	case acceptFriendRequest(requestId: UUID)

	/// Decline/Reject a friend request
	case declineFriendRequest(requestId: UUID)

	/// Remove a friend
	case removeFriend(currentUserId: UUID, friendId: UUID)

	// MARK: - Activity Type Operations

	/// Batch update activity types (create, update, delete)
	case batchUpdateActivityTypes(userId: UUID, update: BatchActivityTypeUpdateDTO)

	// MARK: - Activity Operations

	/// Create a new activity
	case createActivity(activity: ActivityDTO)

	/// Update an existing activity
	case updateActivity(activityId: UUID, update: ActivityDTO)

	/// Delete an activity
	case deleteActivity(activityId: UUID)

	/// Join an activity
	case joinActivity(activityId: UUID, userId: UUID)

	/// Leave an activity
	case leaveActivity(activityId: UUID, userId: UUID)

	/// Invite user to activity
	case inviteToActivity(activityId: UUID, invitedUserId: UUID)

	/// Remove user from activity
	case removeFromActivity(activityId: UUID, userId: UUID)

	// MARK: - Reporting & Blocking Operations

	/// Report a user
	case reportUser(report: CreateReportedContentDTO)

	/// Report a chat message
	case reportChatMessage(report: CreateReportedContentDTO)

	/// Block a user
	case blockUser(blockerId: UUID, blockedId: UUID, reason: String)

	/// Unblock a user
	case unblockUser(blockerId: UUID, blockedId: UUID)

	// MARK: - User Management Operations

	/// Delete user account
	case deleteUser(userId: UUID)

	// MARK: - Chat Operations

	/// Fetch activity chat messages
	case fetchActivityChats(activityId: UUID)

	/// Send a chat message
	case sendChatMessage(message: CreateChatMessageDTO)

	// MARK: - Feedback Operations

	/// Submit user feedback
	case submitFeedback(feedback: FeedbackSubmissionDTO)

	// MARK: - Contacts Operations

	/// Cross-reference phone numbers with existing users
	case crossReferenceContacts(request: ContactCrossReferenceRequestDTO)

	// MARK: - Notification Operations

	/// Register device token for push notifications
	case registerDeviceToken(token: DeviceTokenDTO)

	/// Unregister device token for push notifications
	case unregisterDeviceToken(token: DeviceTokenDTO)

	/// Update notification preferences
	case updateNotificationPreferences(preferences: NotificationPreferencesDTO)

	/// Update device token (legacy PATCH method)
	case patchDeviceToken(userId: UUID, token: String)

	// MARK: - Activity Management Operations

	/// Partial update activity (PATCH)
	case partialUpdateActivity(activityId: UUID, update: ActivityPartialUpdateDTO)

	/// Toggle user participation in activity
	case toggleActivityParticipation(activityId: UUID, userId: UUID)

	/// Report an activity
	case reportActivity(report: CreateReportedContentDTO)

	// MARK: - Configuration Properties

	/// HTTP method for this operation
	var method: HTTPMethod {
		switch self {
		case .addProfileInterest,
			.sendFriendRequest,
			.createActivity,
			.reportUser,
			.reportChatMessage,
			.sendChatMessage,
			.submitFeedback,
			.reportActivity,
			.crossReferenceContacts,
			.registerDeviceToken,
			.updateNotificationPreferences:
			return .post

		case .updateSocialMedia,
			.acceptFriendRequest,
			.declineFriendRequest,
			.batchUpdateActivityTypes,
			.updateActivity,
			.toggleActivityParticipation:
			return .put

		case .removeProfileInterest,
			.removeFriend,
			.deleteActivity,
			.leaveActivity,
			.removeFromActivity,
			.deleteUser,
			.unregisterDeviceToken:
			return .delete

		case .joinActivity,
			.inviteToActivity,
			.blockUser,
			.unblockUser,
			.fetchActivityChats:
			return .post

		case .partialUpdateActivity,
			.patchDeviceToken:
			return .patch
		}
	}

	/// API endpoint path for this operation
	var endpoint: String {
		switch self {
		// Profile
		case .addProfileInterest(let userId, _):
			return "users/\(userId)/interests"
		case .removeProfileInterest(let userId, let interest):
			// URL encode the interest name
			let encoded = interest.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? interest
			return "users/\(userId)/interests/\(encoded)"
		case .updateSocialMedia(let userId, _):
			return "users/\(userId)/social-media"

		// Friends
		case .sendFriendRequest:
			return "friend-requests"
		case .acceptFriendRequest(let requestId),
			.declineFriendRequest(let requestId):
			return "friend-requests/\(requestId)"
		case .removeFriend(let currentUserId, let friendId):
			return "api/v1/users/friends/\(currentUserId)/\(friendId)"

		// Activity Types
		case .batchUpdateActivityTypes(let userId, _):
			return "users/\(userId)/activity-types"

		// Activities
		case .createActivity:
			return "activities"
		case .updateActivity(let activityId, _):
			return "activities/\(activityId)"
		case .deleteActivity(let activityId):
			return "activities/\(activityId)"
		case .joinActivity(let activityId, _):
			return "activities/\(activityId)/join"
		case .leaveActivity(let activityId, _):
			return "activities/\(activityId)/leave"
		case .inviteToActivity(let activityId, _):
			return "activities/\(activityId)/invite"
		case .removeFromActivity(let activityId, _):
			return "activities/\(activityId)/remove"

		// Reporting & Blocking
		case .reportUser:
			return "reports/create"
		case .reportChatMessage:
			return "reports/create"
		case .blockUser:
			return "blocked-users/block"
		case .unblockUser:
			return "blocked-users/unblock"

		// User Management
		case .deleteUser(let userId):
			return "users/\(userId)"

		// Chats
		case .fetchActivityChats(let activityId):
			return "activities/\(activityId)/chats"
		case .sendChatMessage:
			return "chatMessages"

		// Feedback
		case .submitFeedback:
			return "feedback"

		// Activity Management
		case .partialUpdateActivity(let activityId, _):
			return "activities/\(activityId)/partial"
		case .toggleActivityParticipation(let activityId, let userId):
			return "activities/\(activityId)/toggleStatus/\(userId)"
		case .reportActivity:
			return "reports/activities"

		// Contacts
		case .crossReferenceContacts:
			return "users/contacts/cross-reference"

		// Notifications
		case .registerDeviceToken:
			return "notifications/device-tokens/register"
		case .unregisterDeviceToken:
			return "notifications/device-tokens/unregister"
		case .updateNotificationPreferences(let preferences):
			return "notifications/preferences/\(preferences.userId)"
		case .patchDeviceToken(let userId, _):
			return "users/\(userId)/device-token"
		}
	}

	/// Query parameters for the API request
	var parameters: [String: String]? {
		switch self {
		case .acceptFriendRequest:
			return ["friendRequestAction": "accept"]
		case .declineFriendRequest:
			return ["friendRequestAction": "reject"]
		case .unblockUser(let blockerId, let blockedId):
			return [
				"blockerId": blockerId.uuidString,
				"blockedId": blockedId.uuidString,
			]
		default:
			return nil
		}
	}

	/// Cache keys to invalidate after successful operation
	var cacheInvalidationKeys: [String] {
		switch self {
		// Profile
		case .addProfileInterest(let userId, _),
			.removeProfileInterest(let userId, _):
			return ["profileInterests-\(userId)"]
		case .updateSocialMedia(let userId, _):
			return ["profileSocialMedia-\(userId)"]

		// Friends
		case .sendFriendRequest(let request):
			return [
				"friendRequests-\(request.receiverUserId)",
				"sentFriendRequests-\(request.senderUserId)",
				"recommendedFriends-\(request.senderUserId)",
			]
		case .acceptFriendRequest, .declineFriendRequest:
			// Note: These need to be updated with specific user IDs when used
			return ["friends", "friendRequests", "sentFriendRequests"]
		case .removeFriend(let currentUserId, _):
			return ["friends-\(currentUserId)"]

		// Activity Types
		case .batchUpdateActivityTypes:
			return ["activityTypes"]

		// Activities
		case .createActivity,
			.updateActivity,
			.deleteActivity,
			.joinActivity,
			.leaveActivity,
			.inviteToActivity,
			.removeFromActivity:
			// Invalidate all activity-related caches
			// In a real implementation, we'd want to be more specific
			return ["activities"]

		// Reporting & Blocking
		case .reportUser, .reportChatMessage:
			return []  // No cache invalidation needed for reports
		case .blockUser(let blockerId, _, _):
			return ["friends-\(blockerId)"]
		case .unblockUser(let blockerId, _):
			return ["friends-\(blockerId)"]

		// User Management
		case .deleteUser:
			// Clear all user-related caches
			return []

		// Chats
		case .fetchActivityChats(let activityId):
			return ["activityChats-\(activityId)"]
		case .sendChatMessage(let message):
			return ["activityChats-\(message.activityId)"]

		// Feedback
		case .submitFeedback:
			return []  // No cache invalidation needed for feedback

		// Activity Management
		case .partialUpdateActivity(let activityId, _),
			.toggleActivityParticipation(let activityId, _):
			return ["activities", "activity-\(activityId)"]
		case .reportActivity:
			return []  // No cache invalidation needed for reports

		// Contacts
		case .crossReferenceContacts:
			return []  // No cache invalidation needed for contact lookup

		// Notifications
		case .registerDeviceToken,
			.unregisterDeviceToken,
			.updateNotificationPreferences,
			.patchDeviceToken:
			return []  // No cache invalidation needed for notification operations
		}
	}

	/// Human-readable name for logging
	var displayName: String {
		switch self {
		case .addProfileInterest:
			return "Add Profile Interest"
		case .removeProfileInterest:
			return "Remove Profile Interest"
		case .updateSocialMedia:
			return "Update Social Media"
		case .sendFriendRequest:
			return "Send Friend Request"
		case .acceptFriendRequest:
			return "Accept Friend Request"
		case .declineFriendRequest:
			return "Decline Friend Request"
		case .removeFriend:
			return "Remove Friend"
		case .batchUpdateActivityTypes:
			return "Batch Update Activity Types"
		case .createActivity:
			return "Create Activity"
		case .updateActivity:
			return "Update Activity"
		case .deleteActivity:
			return "Delete Activity"
		case .joinActivity:
			return "Join Activity"
		case .leaveActivity:
			return "Leave Activity"
		case .inviteToActivity:
			return "Invite to Activity"
		case .removeFromActivity:
			return "Remove from Activity"
		case .reportUser:
			return "Report User"
		case .reportChatMessage:
			return "Report Chat Message"
		case .blockUser:
			return "Block User"
		case .unblockUser:
			return "Unblock User"
		case .deleteUser:
			return "Delete User"
		case .fetchActivityChats:
			return "Fetch Activity Chats"
		case .sendChatMessage:
			return "Send Chat Message"
		case .submitFeedback:
			return "Submit Feedback"
		case .partialUpdateActivity:
			return "Partial Update Activity"
		case .toggleActivityParticipation:
			return "Toggle Activity Participation"
		case .reportActivity:
			return "Report Activity"
		case .crossReferenceContacts:
			return "Cross-Reference Contacts"
		case .registerDeviceToken:
			return "Register Device Token"
		case .unregisterDeviceToken:
			return "Unregister Device Token"
		case .updateNotificationPreferences:
			return "Update Notification Preferences"
		case .patchDeviceToken:
			return "Update Device Token"
		}
	}

	/// Get the request body for this operation type
	/// Returns nil if the operation doesn't have a body
	func getBody<T>() -> T? where T: Encodable {
		switch self {
		case .addProfileInterest(_, let interest):
			return interest as? T
		case .updateSocialMedia(_, let socialMedia):
			return socialMedia as? T
		case .sendFriendRequest(let request):
			return request as? T
		case .acceptFriendRequest, .declineFriendRequest:
			return EmptyRequestBody() as? T
		case .removeProfileInterest, .removeFriend, .deleteActivity, .leaveActivity, .removeFromActivity:
			return EmptyRequestBody() as? T
		case .batchUpdateActivityTypes(_, let update):
			return update as? T
		case .createActivity(let activity):
			return activity as? T
		case .updateActivity(_, let update):
			return update as? T
		case .joinActivity(_, let userId):
			// Create a DTO for join operation if needed
			return EmptyRequestBody() as? T
		case .inviteToActivity(_, let userId):
			// Create a DTO for invite operation if needed
			return EmptyRequestBody() as? T
		case .reportUser(let report):
			return report as? T
		case .reportChatMessage(let report):
			return report as? T
		case .blockUser(let blockerId, let blockedId, let reason):
			// Create a block DTO with all required fields
			let blockDTO = BlockedUserCreationDTO(blockerId: blockerId, blockedId: blockedId, reason: reason)
			return blockDTO as? T
		case .unblockUser:
			return EmptyRequestBody() as? T
		case .deleteUser:
			return EmptyRequestBody() as? T
		case .fetchActivityChats:
			return EmptyRequestBody() as? T
		case .sendChatMessage(let message):
			return message as? T
		case .submitFeedback(let feedback):
			return feedback as? T
		case .partialUpdateActivity(_, let update):
			return update as? T
		case .toggleActivityParticipation:
			return EmptyRequestBody() as? T
		case .reportActivity(let report):
			return report as? T
		case .crossReferenceContacts(let request):
			return request as? T
		case .registerDeviceToken(let token):
			return token as? T
		case .unregisterDeviceToken(let token):
			return token as? T
		case .updateNotificationPreferences(let preferences):
			return preferences as? T
		case .patchDeviceToken(_, let token):
			let tokenData = ["deviceToken": token]
			return tokenData as? T
		}
	}
}

// MARK: - Write Operation Factory Extension

extension WriteOperationType {

	/// Convert this write operation type to a WriteOperation struct
	/// This provides a bridge between the enum config and the actual operation
	func toWriteOperation<Body: Encodable>() -> WriteOperation<Body> {
		return WriteOperation(
			method: self.method,
			endpoint: self.endpoint,
			body: self.getBody(),
			parameters: self.parameters,
			cacheInvalidationKeys: self.cacheInvalidationKeys
		)
	}

	/// Create a WriteOperation with explicit body (overriding the enum's default)
	func toWriteOperation<Body: Encodable>(withBody body: Body) -> WriteOperation<Body> {
		return WriteOperation(
			method: self.method,
			endpoint: self.endpoint,
			body: body,
			parameters: self.parameters,
			cacheInvalidationKeys: self.cacheInvalidationKeys
		)
	}
}

// MARK: - DataService Extension for Convenience

extension IDataService {

	/// Perform a write operation using WriteOperationType configuration
	func write<Response: Decodable>(
		_ operationType: WriteOperationType,
		invalidateCache: Bool = true
	) async -> DataResult<Response> {
		let operation: WriteOperation<EmptyRequestBody> = operationType.toWriteOperation()
		return await write(operation, invalidateCache: invalidateCache)
	}

	/// Perform a write operation using WriteOperationType configuration with explicit body
	func write<Body: Encodable, Response: Decodable>(
		_ operationType: WriteOperationType,
		body: Body,
		invalidateCache: Bool = true
	) async -> DataResult<Response> {
		let operation = operationType.toWriteOperation(withBody: body)
		return await write(operation, invalidateCache: invalidateCache)
	}

	/// Perform a write operation without response using WriteOperationType
	func writeWithoutResponse(
		_ operationType: WriteOperationType,
		invalidateCache: Bool = true
	) async -> DataResult<EmptyResponse> {
		let operation: WriteOperation<EmptyRequestBody> = operationType.toWriteOperation()
		return await writeWithoutResponse(operation, invalidateCache: invalidateCache)
	}
}
