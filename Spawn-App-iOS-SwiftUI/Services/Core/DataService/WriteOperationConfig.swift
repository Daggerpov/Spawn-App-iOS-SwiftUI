//
//  WriteOperationConfig.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-25.
//
//  Configuration for write operations (POST, PUT, PATCH, DELETE).
//  This file centralizes all write operation definitions, making it easy to
//  add new operations or modify existing ones. Similar to DataTypeConfig for reads.
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
	case createActivity(activity: CreateActivityDTO)

	/// Update an existing activity
	case updateActivity(activityId: UUID, update: UpdateActivityDTO)

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
	case reportUser(report: CreateReportDTO)

	/// Block a user
	case blockUser(blockerId: UUID, blockedId: UUID, reason: String)

	/// Unblock a user
	case unblockUser(blockerId: UUID, blockedId: UUID)

	// MARK: - Configuration Properties

	/// HTTP method for this operation
	var method: HTTPMethod {
		switch self {
		case .addProfileInterest,
			.sendFriendRequest,
			.createActivity,
			.reportUser:
			return .post

		case .updateSocialMedia,
			.acceptFriendRequest,
			.declineFriendRequest,
			.batchUpdateActivityTypes,
			.updateActivity:
			return .put

		case .removeProfileInterest,
			.removeFriend,
			.deleteActivity,
			.leaveActivity,
			.removeFromActivity:
			return .delete

		case .joinActivity,
			.inviteToActivity,
			.blockUser,
			.unblockUser:
			return .post
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
			return "reports/users"
		case .blockUser:
			return "blocks"
		case .unblockUser(let blockerId, let blockedId):
			return "blocks/\(blockerId)/\(blockedId)"
		}
	}

	/// Query parameters for the API request
	var parameters: [String: String]? {
		switch self {
		case .acceptFriendRequest:
			return ["friendRequestAction": "accept"]
		case .declineFriendRequest:
			return ["friendRequestAction": "reject"]
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
		case .reportUser:
			return []
		case .blockUser(let blockerId, _),
			.unblockUser(let blockerId, _):
			return ["friends-\(blockerId)"]
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
		case .blockUser:
			return "Block User"
		case .unblockUser:
			return "Unblock User"
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
		case .blockUser(_, _, let reason):
			// Create a block DTO with reason
			return ["reason": reason] as? T
		case .unblockUser:
			return EmptyRequestBody() as? T
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
