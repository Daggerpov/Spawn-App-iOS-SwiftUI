//
//  DataFetcherConfig.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-24.
//
//  Configuration for DataFetcher endpoints and cache keys.
//  This file centralizes all data type definitions, making it easy to
//  add new data types or modify existing ones.
//

import Foundation

// MARK: - Data Type Enum

/// Enum representing all data types that can be fetched via DataFetcher
enum DataType {
	// Activities
	case activities(userId: UUID)
	case activityTypes

	// Friends
	case friends(userId: UUID)
	case recommendedFriends(userId: UUID)
	case friendRequests(userId: UUID)
	case sentFriendRequests(userId: UUID)

	// Profile
	case profileStats(userId: UUID)
	case profileInterests(userId: UUID)
	case profileSocialMedia(userId: UUID)
	case profileActivities(userId: UUID)

	// MARK: - Configuration Properties

	/// API endpoint path for this data type
	var endpoint: String {
		switch self {
		// Activities
		case .activities(let userId):
			return "users/\(userId)/activities"
		case .activityTypes:
			return "activity-types"

		// Friends
		case .friends(let userId):
			return "users/friends/\(userId)"
		case .recommendedFriends(let userId):
			return "users/recommended-friends/\(userId)"
		case .friendRequests(let userId):
			return "friend-requests/incoming/\(userId)"
		case .sentFriendRequests(let userId):
			return "friend-requests/sent/\(userId)"

		// Profile
		case .profileStats(let userId):
			return "users/\(userId)/stats"
		case .profileInterests(let userId):
			return "users/\(userId)/interests"
		case .profileSocialMedia(let userId):
			return "users/\(userId)/social-media"
		case .profileActivities(let userId):
			return "activities/profile/\(userId)"
		}
	}

	/// Cache key for this data type
	var cacheKey: String {
		switch self {
		// Activities
		case .activities(let userId):
			return "activities-\(userId)"
		case .activityTypes:
			return "activityTypes"

		// Friends
		case .friends(let userId):
			return "friends-\(userId)"
		case .recommendedFriends(let userId):
			return "recommendedFriends-\(userId)"
		case .friendRequests(let userId):
			return "friendRequests-\(userId)"
		case .sentFriendRequests(let userId):
			return "sentFriendRequests-\(userId)"

		// Profile
		case .profileStats(let userId):
			return "profileStats-\(userId)"
		case .profileInterests(let userId):
			return "profileInterests-\(userId)"
		case .profileSocialMedia(let userId):
			return "profileSocialMedia-\(userId)"
		case .profileActivities(let userId):
			return "profileActivities-\(userId)"
		}
	}

	/// Optional query parameters for the API request
	var parameters: [String: String]? {
		switch self {
		case .profileActivities(let userId):
			// Profile activities require requesting user ID as parameter
			guard let requestingUserId = UserAuthViewModel.shared.spawnUser?.id else {
				return nil
			}
			return ["requestingUserId": requestingUserId.uuidString]
		default:
			return nil
		}
	}

	/// Human-readable name for logging
	var displayName: String {
		switch self {
		case .activities:
			return "Activities"
		case .activityTypes:
			return "Activity Types"
		case .friends:
			return "Friends"
		case .recommendedFriends:
			return "Recommended Friends"
		case .friendRequests:
			return "Friend Requests"
		case .sentFriendRequests:
			return "Sent Friend Requests"
		case .profileStats:
			return "Profile Stats"
		case .profileInterests:
			return "Profile Interests"
		case .profileSocialMedia:
			return "Profile Social Media"
		case .profileActivities:
			return "Profile Activities"
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
