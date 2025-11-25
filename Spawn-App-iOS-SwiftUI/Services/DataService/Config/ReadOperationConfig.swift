//
//  ReadOperationConfig.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-24.
//  Renamed from DataTypeConfig.swift on 2025-11-25.
//
//  Configuration for read operations (GET) for the data service layer.
//  This file centralizes all read operation definitions, making it easy to
//  add new operations or modify existing ones. Pairs with WriteOperationConfig.swift.
//

import Foundation

// MARK: - Data Type Enum

/// Enum representing all data types that can be fetched via DataService
/// Each case includes endpoint, cache key, and optional parameters
enum DataType {
	// MARK: - Activities

	/// All activities for a user
	case activities(userId: UUID)

	/// Single activity by ID
	case activity(activityId: UUID, requestingUserId: UUID, autoJoin: Bool = false)

	/// Activity types
	case activityTypes

	/// Upcoming activities for a user
	case upcomingActivities(userId: UUID)

	/// Activity chat messages
	case activityChats(activityId: UUID)

	// MARK: - Friends

	/// All friends for a user
	case friends(userId: UUID)

	/// Recommended friends for a user
	case recommendedFriends(userId: UUID)

	/// Incoming friend requests for a user
	case friendRequests(userId: UUID)

	/// Sent friend requests from a user
	case sentFriendRequests(userId: UUID)

	/// Check if two users are friends
	case isFriend(currentUserId: UUID, otherUserId: UUID)

	// MARK: - Profile

	/// User profile statistics
	case profileStats(userId: UUID)

	/// User profile information
	case profileInfo(userId: UUID, requestingUserId: UUID?)

	/// User interests
	case profileInterests(userId: UUID)

	/// User social media links
	case profileSocialMedia(userId: UUID)

	/// Profile activities (both upcoming and past)
	case profileActivities(userId: UUID)

	// MARK: - Calendar

	/// Calendar activities for a specific month
	case calendar(userId: UUID, month: Int, year: Int, requestingUserId: UUID?)

	/// All calendar activities for a user
	case calendarAll(userId: UUID, requestingUserId: UUID?)

	// MARK: - Configuration Properties

	/// API endpoint path for this data type
	var endpoint: String {
		switch self {
		// Activities
		case .activities(let userId):
			return "users/\(userId)/activities"
		case .activity(let activityId, _):
			return "activities/\(activityId)"
		case .activityTypes:
			return "activity-types"
		case .upcomingActivities(let userId):
			return "activities/user/\(userId)/upcoming"
		case .activityChats(let activityId):
			return "activities/\(activityId)/chats"

		// Friends
		case .friends(let userId):
			return "users/friends/\(userId)"
		case .recommendedFriends(let userId):
			return "users/recommended-friends/\(userId)"
		case .friendRequests(let userId):
			return "friend-requests/incoming/\(userId)"
		case .sentFriendRequests(let userId):
			return "friend-requests/sent/\(userId)"
		case .isFriend(let currentUserId, let otherUserId):
			return "users/\(currentUserId)/is-friend/\(otherUserId)"

		// Profile
		case .profileStats(let userId):
			return "users/\(userId)/stats"
		case .profileInfo(let userId, _):
			return "users/\(userId)"
		case .profileInterests(let userId):
			return "users/\(userId)/interests"
		case .profileSocialMedia(let userId):
			return "users/\(userId)/social-media"
		case .profileActivities(let userId):
			return "activities/profile/\(userId)"

		// Calendar
		case .calendar(let userId, _, _, _):
			return "users/\(userId)/calendar"
		case .calendarAll(let userId, _):
			return "users/\(userId)/calendar"
		}
	}

	/// Cache key for this data type
	var cacheKey: String {
		switch self {
		// Activities
		case .activities(let userId):
			return "activities-\(userId)"
		case .activity(let activityId, _):
			return "activity_\(activityId)"
		case .activityTypes:
			return "activityTypes"
		case .upcomingActivities(let userId):
			return "upcomingActivities_\(userId)"
		case .activityChats(let activityId):
			return "activityChats-\(activityId)"

		// Friends
		case .friends(let userId):
			return "friends-\(userId)"
		case .recommendedFriends(let userId):
			return "recommendedFriends-\(userId)"
		case .friendRequests(let userId):
			return "friendRequests-\(userId)"
		case .sentFriendRequests(let userId):
			return "sentFriendRequests-\(userId)"
		case .isFriend(let currentUserId, let otherUserId):
			return "isFriend_\(currentUserId)_\(otherUserId)"

		// Profile
		case .profileStats(let userId):
			return "profileStats-\(userId)"
		case .profileInfo(let userId):
			return "profileInfo_\(userId)"
		case .profileInterests(let userId):
			return "profileInterests-\(userId)"
		case .profileSocialMedia(let userId):
			return "profileSocialMedia-\(userId)"
		case .profileActivities(let userId):
			return "profileActivities-\(userId)"

		// Calendar
		case .calendar(let userId, let month, let year, _):
			return "calendar_\(userId)_\(month)_\(year)"
		case .calendarAll(let userId, _):
			return "calendar_all_\(userId)"
		}
	}

	/// Optional query parameters for the API request
	var parameters: [String: String]? {
		switch self {
		case .activity(_, let requestingUserId, let autoJoin):
			var params = ["requestingUserId": requestingUserId.uuidString]
			if autoJoin {
				params["autoJoin"] = "true"
			}
			return params

		case .profileInfo(_, let requestingUserId):
			if let requestingUserId = requestingUserId {
				return ["requestingUserId": requestingUserId.uuidString]
			}
			return nil

		case .profileActivities:
			// Profile activities require requesting user ID as parameter
			guard let requestingUserId = UserAuthViewModel.shared.spawnUser?.id else {
				return nil
			}
			return ["requestingUserId": requestingUserId.uuidString]

		case .calendar(_, let month, let year, let requestingUserId):
			var params = [
				"month": String(month),
				"year": String(year),
			]
			if let requestingUserId = requestingUserId {
				params["requestingUserId"] = requestingUserId.uuidString
			}
			return params

		case .calendarAll(_, let requestingUserId):
			if let requestingUserId = requestingUserId {
				return ["requestingUserId": requestingUserId.uuidString]
			}
			return nil

		case .activityChats:
			return nil

		default:
			return nil
		}
	}

	/// Human-readable name for logging
	var displayName: String {
		switch self {
		case .activities:
			return "Activities"
		case .activity:
			return "Activity"
		case .activityTypes:
			return "Activity Types"
		case .upcomingActivities:
			return "Upcoming Activities"
		case .activityChats:
			return "Activity Chats"
		case .friends:
			return "Friends"
		case .recommendedFriends:
			return "Recommended Friends"
		case .friendRequests:
			return "Friend Requests"
		case .sentFriendRequests:
			return "Sent Friend Requests"
		case .isFriend:
			return "Is Friend"
		case .profileStats:
			return "Profile Stats"
		case .profileInfo:
			return "Profile Info"
		case .profileInterests:
			return "Profile Interests"
		case .profileSocialMedia:
			return "Profile Social Media"
		case .profileActivities:
			return "Profile Activities"
		case .calendar:
			return "Calendar"
		case .calendarAll:
			return "All Calendar Activities"
		}
	}
}

// MARK: - Cache Operations

/// Helper struct to encapsulate cache operations for each data type
struct CacheOperations<T> {
	let provider: () -> T?
	let updater: (T) -> Void
}

/// Factory for creating cache operations for each data type
struct CacheOperationsFactory {
	/// Generic helper for user-specific dictionary caches (data first, userId second pattern)
	private static func userDictionaryOps<T, Value>(
		expectedType: T.Type,
		dictionary: [UUID: Value],
		userId: UUID,
		updater: @escaping (Value, UUID) -> Void
	) -> CacheOperations<T>? {
		guard T.self == Value.self else { return nil }
		return CacheOperations(
			provider: { dictionary[userId] as? T },
			updater: { data in
				guard let value = data as? Value else { return }
				updater(value, userId)
			}
		)
	}

	/// Generic helper for user-specific dictionary caches (userId first, data second pattern)
	private static func profileDictionaryOps<T, Value>(
		expectedType: T.Type,
		dictionary: [UUID: Value],
		userId: UUID,
		updater: @escaping (UUID, Value) -> Void
	) -> CacheOperations<T>? {
		guard T.self == Value.self else { return nil }
		return CacheOperations(
			provider: { dictionary[userId] as? T },
			updater: { data in
				guard let value = data as? Value else { return }
				updater(userId, value)
			}
		)
	}

	static func operations<T>(for dataType: DataType, appCache: AppCache) -> CacheOperations<T>? {
		switch dataType {
		// Activities
		case .activities(let userId):
			return userDictionaryOps(
				expectedType: T.self,
				dictionary: appCache.activities,
				userId: userId,
				updater: appCache.updateActivitiesForUser
			)

		case .activityTypes:
			guard T.self == [ActivityTypeDTO].self else { return nil }
			return CacheOperations(
				provider: {
					let types = appCache.activityTypes
					return (types.isEmpty ? nil : types) as? T
				},
				updater: { data in
					guard let types = data as? [ActivityTypeDTO] else { return }
					appCache.updateActivityTypes(types)
				}
			)

		// Friends
		case .friends(let userId):
			return userDictionaryOps(
				expectedType: T.self,
				dictionary: appCache.friends,
				userId: userId,
				updater: appCache.updateFriendsForUser
			)

		case .recommendedFriends(let userId):
			return userDictionaryOps(
				expectedType: T.self,
				dictionary: appCache.recommendedFriends,
				userId: userId,
				updater: appCache.updateRecommendedFriendsForUser
			)

		case .friendRequests(let userId):
			return userDictionaryOps(
				expectedType: T.self,
				dictionary: appCache.friendRequests,
				userId: userId,
				updater: appCache.updateFriendRequestsForUser
			)

		case .sentFriendRequests(let userId):
			return userDictionaryOps(
				expectedType: T.self,
				dictionary: appCache.sentFriendRequests,
				userId: userId,
				updater: appCache.updateSentFriendRequestsForUser
			)

		// Profile
		case .profileStats(let userId):
			return profileDictionaryOps(
				expectedType: T.self,
				dictionary: appCache.profileStats,
				userId: userId,
				updater: appCache.updateProfileStats
			)

		case .profileInterests(let userId):
			return profileDictionaryOps(
				expectedType: T.self,
				dictionary: appCache.profileInterests,
				userId: userId,
				updater: appCache.updateProfileInterests
			)

		case .profileSocialMedia(let userId):
			return profileDictionaryOps(
				expectedType: T.self,
				dictionary: appCache.profileSocialMedia,
				userId: userId,
				updater: appCache.updateProfileSocialMedia
			)

		case .profileActivities(let userId):
			return profileDictionaryOps(
				expectedType: T.self,
				dictionary: appCache.profileActivities,
				userId: userId,
				updater: appCache.updateProfileActivities
			)

		default:
			return nil
		}
	}
}
