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
	case activityTypes(userId: UUID)

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

	// MARK: - Blocking & Reporting

	/// Check if a user is blocked
	case isUserBlocked(blockerId: UUID, blockedId: UUID)

	/// Get list of blocked users (returns UUIDs or full DTOs based on parameter)
	case blockedUsers(blockerId: UUID, returnOnlyIds: Bool = true)

	/// Get reports made by a user (simplified DTOs)
	case reportsByUser(reporterId: UUID)

	/// Get reports about a user (admin only)
	case reportsAboutUser(userId: UUID)

	// MARK: - Notifications

	/// Get notification preferences for a user
	case notificationPreferences(userId: UUID)

	// MARK: - Configuration Properties

	/// API endpoint path for this data type
	var endpoint: String {
		switch self {
		// Activities
		case .activities(let userId):
			return "users/\(userId)/activities"
		case .activity(let activityId, _, _):
			return "activities/\(activityId)"
		case .activityTypes(let userId):
			return "users/\(userId)/activity-types"
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

		// Blocking & Reporting
		case .isUserBlocked:
			return "blocked-users/is-blocked"
		case .blockedUsers(let blockerId, _):
			return "blocked-users/\(blockerId)"
		case .reportsByUser(let reporterId):
			return "reports/fetch/reporter/\(reporterId)"
		case .reportsAboutUser(let userId):
			return "reports/\(userId)"

		// Notifications
		case .notificationPreferences(let userId):
			return "notifications/preferences/\(userId)"
		}
	}

	/// Cache key for this data type
	var cacheKey: String {
		switch self {
		// Activities
		case .activities(let userId):
			return "activities-\(userId)"
		case .activity(let activityId, _, _):
			return "activity_\(activityId)"
		case .activityTypes(let userId):
			return "activityTypes_\(userId)"
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
		case .profileInfo(let userId, _):
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

		// Blocking & Reporting
		case .isUserBlocked(let blockerId, let blockedId):
			return "isUserBlocked_\(blockerId)_\(blockedId)"
		case .blockedUsers(let blockerId, let returnOnlyIds):
			return "blockedUsers_\(blockerId)_\(returnOnlyIds)"
		case .reportsByUser(let reporterId):
			return "reportsByUser_\(reporterId)"
		case .reportsAboutUser(let userId):
			return "reportsAboutUser_\(userId)"

		// Notifications
		case .notificationPreferences(let userId):
			return "notificationPreferences_\(userId)"
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

		case .isUserBlocked(let blockerId, let blockedId):
			return [
				"blockerId": blockerId.uuidString,
				"blockedId": blockedId.uuidString,
			]

		case .blockedUsers(_, let returnOnlyIds):
			return ["returnOnlyIds": returnOnlyIds ? "true" : "false"]

		case .reportsByUser, .reportsAboutUser, .notificationPreferences:
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
		case .isUserBlocked:
			return "Is User Blocked"
		case .blockedUsers:
			return "Blocked Users"
		case .reportsByUser:
			return "Reports By User"
		case .reportsAboutUser:
			return "Reports About User"
		case .notificationPreferences:
			return "Notification Preferences"
		}
	}
}

// MARK: - Cache Operations

/// Helper struct to encapsulate cache operations for each data type
struct CacheOperations<T> {
	let provider: () -> T?
	let updater: (T) -> Void
}

/// Protocol for type-erased cache configuration
private protocol CacheConfigProtocol {
	func createOperations<T>(appCache: AppCache) -> CacheOperations<T>?
}

/// Generic cache configuration for user-specific dictionary caches (data first, userId second pattern)
private struct UserDictionaryCacheConfig<Value>: CacheConfigProtocol {
	let dictionary: (AppCache) -> [UUID: Value]
	let updater: (AppCache) -> (Value, UUID) -> Void
	let userId: UUID

	func createOperations<T>(appCache: AppCache) -> CacheOperations<T>? {
		guard T.self == Value.self else { return nil }
		return CacheOperations(
			provider: { dictionary(appCache)[userId] as? T },
			updater: { data in
				guard let value = data as? Value else { return }
				updater(appCache)(value, userId)
			}
		)
	}
}

/// Generic cache configuration for user-specific dictionary caches (userId first, data second pattern)
private struct ProfileDictionaryCacheConfig<Value>: CacheConfigProtocol {
	let dictionary: (AppCache) -> [UUID: Value]
	let updater: (AppCache) -> (UUID, Value) -> Void
	let userId: UUID

	func createOperations<T>(appCache: AppCache) -> CacheOperations<T>? {
		guard T.self == Value.self else { return nil }
		return CacheOperations(
			provider: { dictionary(appCache)[userId] as? T },
			updater: { data in
				guard let value = data as? Value else { return }
				updater(appCache)(userId, value)
			}
		)
	}
}

/// Generic cache configuration for simple (non-dictionary) caches
private struct SimpleCacheConfig<Value>: CacheConfigProtocol {
	let getter: (AppCache) -> Value
	let updater: (AppCache) -> (Value) -> Void
	let shouldReturnNilIfEmpty: Bool

	func createOperations<T>(appCache: AppCache) -> CacheOperations<T>? {
		guard T.self == Value.self else { return nil }
		return CacheOperations(
			provider: {
				let value = getter(appCache)
				if shouldReturnNilIfEmpty, let array = value as? [Any], array.isEmpty {
					return nil
				}
				return value as? T
			},
			updater: { data in
				guard let value = data as? Value else { return }
				updater(appCache)(value)
			}
		)
	}
}

// MARK: - DataType Cache Configuration Extension

extension DataType {
	/// Returns the cache configuration for this data type, or nil if not cacheable
	fileprivate var cacheConfig: CacheConfigProtocol? {
		switch self {
		// Activities
		case .activities(let userId):
			return UserDictionaryCacheConfig<[FullFeedActivityDTO]>(
				dictionary: { $0.activities },
				updater: { appCache in appCache.updateActivitiesForUser },
				userId: userId
			)

		case .activityTypes:
			// Note: Activity types are stored globally (not per-user) in cache for now
			return SimpleCacheConfig<[ActivityTypeDTO]>(
				getter: { $0.activityTypes },
				updater: { appCache in appCache.updateActivityTypes },
				shouldReturnNilIfEmpty: true
			)

		// Friends
		case .friends(let userId):
			return UserDictionaryCacheConfig<[FullFriendUserDTO]>(
				dictionary: { $0.friends },
				updater: { appCache in appCache.updateFriendsForUser },
				userId: userId
			)

		case .recommendedFriends(let userId):
			return UserDictionaryCacheConfig<[RecommendedFriendUserDTO]>(
				dictionary: { $0.recommendedFriends },
				updater: { appCache in appCache.updateRecommendedFriendsForUser },
				userId: userId
			)

		case .friendRequests(let userId):
			return UserDictionaryCacheConfig<[FetchFriendRequestDTO]>(
				dictionary: { $0.friendRequests },
				updater: { appCache in appCache.updateFriendRequestsForUser },
				userId: userId
			)

		case .sentFriendRequests(let userId):
			return UserDictionaryCacheConfig<[FetchSentFriendRequestDTO]>(
				dictionary: { $0.sentFriendRequests },
				updater: { appCache in appCache.updateSentFriendRequestsForUser },
				userId: userId
			)

		// Profile
		case .profileStats(let userId):
			return ProfileDictionaryCacheConfig<UserStatsDTO>(
				dictionary: { $0.profileStats },
				updater: { appCache in appCache.updateProfileStats },
				userId: userId
			)

		case .profileInterests(let userId):
			return ProfileDictionaryCacheConfig<[String]>(
				dictionary: { $0.profileInterests },
				updater: { appCache in appCache.updateProfileInterests },
				userId: userId
			)

		case .profileSocialMedia(let userId):
			return ProfileDictionaryCacheConfig<UserSocialMediaDTO>(
				dictionary: { $0.profileSocialMedia },
				updater: { appCache in appCache.updateProfileSocialMedia },
				userId: userId
			)

		case .profileActivities(let userId):
			return ProfileDictionaryCacheConfig<[ProfileActivityDTO]>(
				dictionary: { $0.profileActivities },
				updater: { appCache in appCache.updateProfileActivities },
				userId: userId
			)

		// Non-cacheable data types
		default:
			return nil
		}
	}
}

/// Factory for creating cache operations for each data type
struct CacheOperationsFactory {
	/// Generic method to create cache operations for any data type
	/// This method uses the cache configuration defined in the DataType enum
	static func operations<T>(for dataType: DataType, appCache: AppCache) -> CacheOperations<T>? {
		return dataType.cacheConfig?.createOperations(appCache: appCache)
	}
}
