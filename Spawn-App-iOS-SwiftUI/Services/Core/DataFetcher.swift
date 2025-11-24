//
//  DataFetcher.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-24.
//
//  DataFetcher is a middle-man service between ViewModels and APIService/AppCache.
//  It handles the common pattern of checking cache first, then fetching from API,
//  and updating the cache. This reduces code duplication across ViewModels and
//  simplifies their dependencies.
//

import Combine
import Foundation

// MARK: - Cache Policy

/// Defines how the DataFetcher should handle caching
enum CachePolicy {
	/// Check cache first, if available use it and optionally refresh in background
	case cacheFirst(backgroundRefresh: Bool = true)
	/// Always fetch from API, bypass cache (but still update cache after fetch)
	case apiOnly
	/// Use only cache, never fetch from API
	case cacheOnly
}

// MARK: - Fetch Result

/// Result of a data fetch operation
enum FetchResult<T> {
	case success(T, source: DataSource)
	case failure(Error)

	enum DataSource {
		case cache
		case api
	}
}

// MARK: - Data Fetcher Protocol

/// Protocol defining the DataFetcher interface
protocol IDataFetcher {
	/// Fetch data with a specified cache policy
	func fetch<T: Decodable>(
		cacheKey: String,
		cachePolicy: CachePolicy,
		cacheProvider: @escaping () -> T?,
		apiProvider: @escaping () async throws -> T,
		cacheUpdater: @escaping (T) -> Void
	) async -> FetchResult<T>

	/// Fetch user-specific data (common pattern with UUID key)
	func fetchUserData<T: Decodable>(
		userId: UUID,
		dataType: String,
		cachePolicy: CachePolicy,
		cacheProvider: @escaping (UUID) -> T?,
		apiProvider: @escaping (UUID) async throws -> T,
		cacheUpdater: @escaping (UUID, T) -> Void
	) async -> FetchResult<T>
}

// MARK: - Data Fetcher Implementation

class DataFetcher: IDataFetcher {
	static let shared = DataFetcher()

	private let apiService: IAPIService
	private let appCache: AppCache

	init(apiService: IAPIService = APIService(), appCache: AppCache = AppCache.shared) {
		self.apiService = apiService
		self.appCache = appCache
	}

	/// Generic fetch method that handles cache-first, then API pattern
	func fetch<T: Decodable>(
		cacheKey: String,
		cachePolicy: CachePolicy,
		cacheProvider: @escaping () -> T?,
		apiProvider: @escaping () async throws -> T,
		cacheUpdater: @escaping (T) -> Void
	) async -> FetchResult<T> {

		switch cachePolicy {
		case .cacheOnly:
			// Only use cache, never fetch from API
			if let cachedData = cacheProvider() {
				print("✅ [DataFetcher] Using cached data for key: \(cacheKey)")
				return .success(cachedData, source: .cache)
			} else {
				print("⚠️ [DataFetcher] No cached data available for key: \(cacheKey)")
				return .failure(DataFetcherError.noCachedData)
			}

		case .apiOnly:
			// Always fetch from API, bypass cache
			print("🔄 [DataFetcher] Fetching from API (cache bypassed) for key: \(cacheKey)")
			do {
				let data = try await apiProvider()
				cacheUpdater(data)
				print("✅ [DataFetcher] API fetch successful for key: \(cacheKey)")
				return .success(data, source: .api)
			} catch {
				print("❌ [DataFetcher] API fetch failed for key: \(cacheKey) - \(error)")
				return .failure(error)
			}

		case .cacheFirst(let backgroundRefresh):
			// Check cache first
			if let cachedData = cacheProvider() {
				print("✅ [DataFetcher] Using cached data for key: \(cacheKey)")

				// If background refresh is enabled, fetch from API in background
				if backgroundRefresh {
					Task {
						print("🔄 [DataFetcher] Refreshing cache in background for key: \(cacheKey)")
						do {
							let freshData = try await apiProvider()
							cacheUpdater(freshData)
							print("✅ [DataFetcher] Background refresh successful for key: \(cacheKey)")
						} catch {
							print("⚠️ [DataFetcher] Background refresh failed for key: \(cacheKey) - \(error)")
							// Don't propagate error since we already have cached data
						}
					}
				}

				return .success(cachedData, source: .cache)
			} else {
				// No cached data, fetch from API
				print("🔄 [DataFetcher] No cached data, fetching from API for key: \(cacheKey)")
				do {
					let data = try await apiProvider()
					cacheUpdater(data)
					print("✅ [DataFetcher] API fetch successful for key: \(cacheKey)")
					return .success(data, source: .api)
				} catch {
					print("❌ [DataFetcher] API fetch failed for key: \(cacheKey) - \(error)")
					return .failure(error)
				}
			}
		}
	}

	/// Convenience method for fetching user-specific data (common pattern)
	func fetchUserData<T: Decodable>(
		userId: UUID,
		dataType: String,
		cachePolicy: CachePolicy,
		cacheProvider: @escaping (UUID) -> T?,
		apiProvider: @escaping (UUID) async throws -> T,
		cacheUpdater: @escaping (UUID, T) -> Void
	) async -> FetchResult<T> {

		let cacheKey = "\(dataType)-\(userId)"

		return await fetch(
			cacheKey: cacheKey,
			cachePolicy: cachePolicy,
			cacheProvider: { cacheProvider(userId) },
			apiProvider: { try await apiProvider(userId) },
			cacheUpdater: { data in cacheUpdater(userId, data) }
		)
	}
}

// MARK: - Data Fetcher Error

enum DataFetcherError: Error, LocalizedError {
	case noCachedData
	case apiFailed(Error)

	var errorDescription: String? {
		switch self {
		case .noCachedData:
			return "No cached data available"
		case .apiFailed(let error):
			return "API fetch failed: \(error.localizedDescription)"
		}
	}
}

// MARK: - Specialized Data Fetchers

/// Extension with convenience methods for common data types
extension DataFetcher {

	// MARK: - Activities

	func fetchActivities(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[FullFeedActivityDTO]> {
		return await fetchUserData(
			userId: userId,
			dataType: "activities",
			cachePolicy: cachePolicy,
			cacheProvider: { userId in
				return self.appCache.activities[userId]
			},
			apiProvider: { userId in
				let url = URL(string: APIService.baseURL + "users/\(userId)/activities")!
				let activities: [FullFeedActivityDTO] = try await self.apiService.fetchData(
					from: url,
					parameters: nil
				)
				return activities
			},
			cacheUpdater: { userId, activities in
				self.appCache.updateActivitiesForUser(activities, userId: userId)
			}
		)
	}

	func fetchActivityTypes(
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[ActivityTypeDTO]> {
		return await fetch(
			cacheKey: "activityTypes",
			cachePolicy: cachePolicy,
			cacheProvider: {
				let types = self.appCache.activityTypes
				return types.isEmpty ? nil : types
			},
			apiProvider: {
				let url = URL(string: APIService.baseURL + "activity-types")!
				let types: [ActivityTypeDTO] = try await self.apiService.fetchData(
					from: url,
					parameters: nil
				)
				return types
			},
			cacheUpdater: { types in
				self.appCache.updateActivityTypes(types)
			}
		)
	}

	// MARK: - Friends

	func fetchFriends(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[FullFriendUserDTO]> {
		return await fetchUserData(
			userId: userId,
			dataType: "friends",
			cachePolicy: cachePolicy,
			cacheProvider: { userId in
				return self.appCache.friends[userId]
			},
			apiProvider: { userId in
				let url = URL(string: APIService.baseURL + "users/\(userId)/friends")!
				let friends: [FullFriendUserDTO] = try await self.apiService.fetchData(
					from: url,
					parameters: nil
				)
				return friends
			},
			cacheUpdater: { userId, friends in
				self.appCache.updateFriendsForUser(friends, userId: userId)
			}
		)
	}

	func fetchRecommendedFriends(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[RecommendedFriendUserDTO]> {
		return await fetchUserData(
			userId: userId,
			dataType: "recommendedFriends",
			cachePolicy: cachePolicy,
			cacheProvider: { userId in
				return self.appCache.recommendedFriends[userId]
			},
			apiProvider: { userId in
				let url = URL(string: APIService.baseURL + "users/\(userId)/recommended-friends")!
				let recommendedFriends: [RecommendedFriendUserDTO] = try await self.apiService.fetchData(
					from: url,
					parameters: nil
				)
				return recommendedFriends
			},
			cacheUpdater: { userId, recommendedFriends in
				self.appCache.updateRecommendedFriendsForUser(recommendedFriends, userId: userId)
			}
		)
	}

	func fetchFriendRequests(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[FetchFriendRequestDTO]> {
		return await fetchUserData(
			userId: userId,
			dataType: "friendRequests",
			cachePolicy: cachePolicy,
			cacheProvider: { userId in
				return self.appCache.friendRequests[userId]
			},
			apiProvider: { userId in
				let url = URL(string: APIService.baseURL + "users/\(userId)/friend-requests")!
				let requests: [FetchFriendRequestDTO] = try await self.apiService.fetchData(
					from: url,
					parameters: nil
				)
				return requests
			},
			cacheUpdater: { userId, requests in
				self.appCache.updateFriendRequestsForUser(requests, userId: userId)
			}
		)
	}

	func fetchSentFriendRequests(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[FetchSentFriendRequestDTO]> {
		return await fetchUserData(
			userId: userId,
			dataType: "sentFriendRequests",
			cachePolicy: cachePolicy,
			cacheProvider: { userId in
				return self.appCache.sentFriendRequests[userId]
			},
			apiProvider: { userId in
				let url = URL(string: APIService.baseURL + "users/\(userId)/sent-friend-requests")!
				let requests: [FetchSentFriendRequestDTO] = try await self.apiService.fetchData(
					from: url,
					parameters: nil
				)
				return requests
			},
			cacheUpdater: { userId, requests in
				self.appCache.updateSentFriendRequestsForUser(requests, userId: userId)
			}
		)
	}

	// MARK: - Profile

	func fetchProfileStats(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<UserStatsDTO> {
		return await fetchUserData(
			userId: userId,
			dataType: "profileStats",
			cachePolicy: cachePolicy,
			cacheProvider: { userId in
				return self.appCache.profileStats[userId]
			},
			apiProvider: { userId in
				let url = URL(string: APIService.baseURL + "users/\(userId)/stats")!
				let stats: UserStatsDTO = try await self.apiService.fetchData(
					from: url,
					parameters: nil
				)
				return stats
			},
			cacheUpdater: { userId, stats in
				self.appCache.updateProfileStats(userId, stats)
			}
		)
	}

	func fetchProfileInterests(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[String]> {
		return await fetchUserData(
			userId: userId,
			dataType: "profileInterests",
			cachePolicy: cachePolicy,
			cacheProvider: { userId in
				return self.appCache.profileInterests[userId]
			},
			apiProvider: { userId in
				let url = URL(string: APIService.baseURL + "users/\(userId)/interests")!
				let interests: [String] = try await self.apiService.fetchData(
					from: url,
					parameters: nil
				)
				return interests
			},
			cacheUpdater: { userId, interests in
				self.appCache.updateProfileInterests(userId, interests)
			}
		)
	}

	func fetchProfileSocialMedia(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<UserSocialMediaDTO> {
		return await fetchUserData(
			userId: userId,
			dataType: "profileSocialMedia",
			cachePolicy: cachePolicy,
			cacheProvider: { userId in
				return self.appCache.profileSocialMedia[userId]
			},
			apiProvider: { userId in
				let url = URL(string: APIService.baseURL + "users/\(userId)/social-media")!
				let socialMedia: UserSocialMediaDTO = try await self.apiService.fetchData(
					from: url,
					parameters: nil
				)
				return socialMedia
			},
			cacheUpdater: { userId, socialMedia in
				self.appCache.updateProfileSocialMedia(userId, socialMedia)
			}
		)
	}

	func fetchProfileActivities(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[ProfileActivityDTO]> {
		return await fetchUserData(
			userId: userId,
			dataType: "profileActivities",
			cachePolicy: cachePolicy,
			cacheProvider: { userId in
				return self.appCache.profileActivities[userId]
			},
			apiProvider: { userId in
				let url = URL(string: APIService.baseURL + "users/\(userId)/profile-activities")!
				let activities: [ProfileActivityDTO] = try await self.apiService.fetchData(
					from: url,
					parameters: nil
				)
				return activities
			},
			cacheUpdater: { userId, activities in
				self.appCache.updateProfileActivities(userId, activities)
			}
		)
	}
}
