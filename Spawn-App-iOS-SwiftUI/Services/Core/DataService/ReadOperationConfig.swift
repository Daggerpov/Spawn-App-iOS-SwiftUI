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
	case activity(activityId: UUID, requestingUserId: UUID)

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
	case profileInfo(userId: UUID)

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
		case .profileInfo(let userId):
			return "users/\(userId)/profile-info"
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
		case .activity(_, let requestingUserId):
			return ["requestingUserId": requestingUserId.uuidString]

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
	static func operations<T>(for dataType: DataType, appCache: AppCache) -> CacheOperations<T>? {
		switch dataType {
		// Activities
		case .activities(let userId):
			if T.self == [FullFeedActivityDTO].self {
				return CacheOperations(
					provider: { appCache.activities[userId] as? T },
					updater: { data in
						if let activities = data as? [FullFeedActivityDTO] {
							appCache.updateActivitiesForUser(activities, userId: userId)
						}
					}
				)
			}

		case .activityTypes:
			if T.self == [ActivityTypeDTO].self {
				return CacheOperations(
					provider: {
						let types = appCache.activityTypes
						return (types.isEmpty ? nil : types) as? T
					},
					updater: { data in
						if let types = data as? [ActivityTypeDTO] {
							appCache.updateActivityTypes(types)
						}
					}
				)
			}

		// Friends
		case .friends(let userId):
			if T.self == [FullFriendUserDTO].self {
				return CacheOperations(
					provider: { appCache.friends[userId] as? T },
					updater: { data in
						if let friends = data as? [FullFriendUserDTO] {
							appCache.updateFriendsForUser(friends, userId: userId)
						}
					}
				)
			}

		case .recommendedFriends(let userId):
			if T.self == [RecommendedFriendUserDTO].self {
				return CacheOperations(
					provider: { appCache.recommendedFriends[userId] as? T },
					updater: { data in
						if let friends = data as? [RecommendedFriendUserDTO] {
							appCache.updateRecommendedFriendsForUser(friends, userId: userId)
						}
					}
				)
			}

		case .friendRequests(let userId):
			if T.self == [FetchFriendRequestDTO].self {
				return CacheOperations(
					provider: { appCache.friendRequests[userId] as? T },
					updater: { data in
						if let requests = data as? [FetchFriendRequestDTO] {
							appCache.updateFriendRequestsForUser(requests, userId: userId)
						}
					}
				)
			}

		case .sentFriendRequests(let userId):
			if T.self == [FetchSentFriendRequestDTO].self {
				return CacheOperations(
					provider: { appCache.sentFriendRequests[userId] as? T },
					updater: { data in
						if let requests = data as? [FetchSentFriendRequestDTO] {
							appCache.updateSentFriendRequestsForUser(requests, userId: userId)
						}
					}
				)
			}

		// Profile
		case .profileStats(let userId):
			if T.self == UserStatsDTO.self {
				return CacheOperations(
					provider: { appCache.profileStats[userId] as? T },
					updater: { data in
						if let stats = data as? UserStatsDTO {
							appCache.updateProfileStats(userId, stats)
						}
					}
				)
			}

		case .profileInterests(let userId):
			if T.self == [String].self {
				return CacheOperations(
					provider: { appCache.profileInterests[userId] as? T },
					updater: { data in
						if let interests = data as? [String] {
							appCache.updateProfileInterests(userId, interests)
						}
					}
				)
			}

		case .profileSocialMedia(let userId):
			if T.self == UserSocialMediaDTO.self {
				return CacheOperations(
					provider: { appCache.profileSocialMedia[userId] as? T },
					updater: { data in
						if let socialMedia = data as? UserSocialMediaDTO {
							appCache.updateProfileSocialMedia(userId, socialMedia)
						}
					}
				)
			}

		case .profileActivities(let userId):
			if T.self == [ProfileActivityDTO].self {
				return CacheOperations(
					provider: { appCache.profileActivities[userId] as? T },
					updater: { data in
						if let activities = data as? [ProfileActivityDTO] {
							appCache.updateProfileActivities(userId, activities)
						}
					}
				)
			}
		}

		return nil
	}
}
