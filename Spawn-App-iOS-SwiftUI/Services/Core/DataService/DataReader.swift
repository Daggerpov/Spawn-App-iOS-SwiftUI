//
//  DataReader.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-24.
//  Renamed from DataFetcher.swift on 2025-11-24.
//
//  DataReader handles read operations (GET) for the data service layer.
//  It implements a cache-first pattern: checking cache first, then fetching from API,
//  and updating the cache. This is part of the unified DataService architecture.
//
//  Refactored to use configuration-based approach with DataType enum for better maintainability.
//

import Combine
import Foundation

// MARK: - Data Reader Protocol

/// Protocol defining the DataReader interface for read operations
protocol IDataReader {
	/// Read data using a DataType configuration
	func read<T: Decodable>(
		_ dataType: DataType,
		cachePolicy: CachePolicy
	) async -> DataResult<T>
}

// MARK: - Data Reader Implementation

class DataReader: IDataReader {
	static let shared = DataReader()

	private let apiService: IAPIService
	private let appCache: AppCache

	init(apiService: IAPIService = APIService(), appCache: AppCache = AppCache.shared) {
		self.apiService = apiService
		self.appCache = appCache
	}

	/// Generic read method using DataType configuration
	func read<T: Decodable>(
		_ dataType: DataType,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<T> {

		// Get cache operations for this data type
		guard let cacheOps = CacheOperationsFactory.operations(for: dataType, appCache: appCache) as CacheOperations<T>?
		else {
			print("❌ [DataReader] No cache operations found for \(dataType.displayName)")
			return .failure(DataServiceError.unsupportedDataType)
		}

		let cacheKey = dataType.cacheKey

		switch cachePolicy {
		case .cacheOnly:
			// Only use cache, never fetch from API
			if let cachedData = cacheOps.provider() {
				print("✅ [DataReader] Using cached \(dataType.displayName)")
				return .success(cachedData, source: .cache)
			} else {
				print("⚠️ [DataReader] No cached \(dataType.displayName) available")
				return .failure(DataServiceError.noCachedData)
			}

		case .apiOnly:
			// Always fetch from API, bypass cache
			print("🔄 [DataReader] Fetching \(dataType.displayName) from API (cache bypassed)")
			return await fetchFromAPI(dataType: dataType, cacheOps: cacheOps)

		case .cacheFirst(let backgroundRefresh):
			// Check cache first
			if let cachedData = cacheOps.provider() {
				print("✅ [DataReader] Using cached \(dataType.displayName)")

				// If background refresh is enabled, fetch from API in background
				if backgroundRefresh {
					Task {
						print("🔄 [DataReader] Refreshing \(dataType.displayName) in background")
						let _ = await fetchFromAPI(dataType: dataType, cacheOps: cacheOps)
					}
				}

				return .success(cachedData, source: .cache)
			} else {
				// No cached data, fetch from API
				print("🔄 [DataReader] No cached \(dataType.displayName), fetching from API")
				return await fetchFromAPI(dataType: dataType, cacheOps: cacheOps)
			}
		}
	}

	/// Internal method to fetch from API
	private func fetchFromAPI<T: Decodable>(
		dataType: DataType,
		cacheOps: CacheOperations<T>
	) async -> DataResult<T> {

		// Build URL from endpoint
		guard let url = URL(string: APIService.baseURL + dataType.endpoint) else {
			print("❌ [DataReader] Invalid URL for \(dataType.displayName)")
			return .failure(DataServiceError.invalidURL)
		}

		do {
			// Fetch from API
			let data: T = try await apiService.fetchData(
				from: url,
				parameters: dataType.parameters
			)

			// Update cache
			cacheOps.updater(data)

			print("✅ [DataReader] API fetch successful for \(dataType.displayName)")
			return .success(data, source: .api)

		} catch {
			print("❌ [DataReader] API fetch failed for \(dataType.displayName): \(error)")
			return .failure(error)
		}
	}
}

// MARK: - Convenience Extensions (Optional)

/// Optional convenience methods for common use cases
/// These are just wrappers around the generic read method for better discoverability
extension DataReader {

	// MARK: - Activities

	func readActivities(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[FullFeedActivityDTO]> {
		return await read(.activities(userId: userId), cachePolicy: cachePolicy)
	}

	func readActivityTypes(
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[ActivityTypeDTO]> {
		return await read(.activityTypes, cachePolicy: cachePolicy)
	}

	// MARK: - Friends

	func readFriends(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[FullFriendUserDTO]> {
		return await read(.friends(userId: userId), cachePolicy: cachePolicy)
	}

	func readRecommendedFriends(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[RecommendedFriendUserDTO]> {
		return await read(.recommendedFriends(userId: userId), cachePolicy: cachePolicy)
	}

	func readFriendRequests(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[FetchFriendRequestDTO]> {
		return await read(.friendRequests(userId: userId), cachePolicy: cachePolicy)
	}

	func readSentFriendRequests(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[FetchSentFriendRequestDTO]> {
		return await read(.sentFriendRequests(userId: userId), cachePolicy: cachePolicy)
	}

	// MARK: - Profile

	func readProfileStats(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<UserStatsDTO> {
		return await read(.profileStats(userId: userId), cachePolicy: cachePolicy)
	}

	func readProfileInterests(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[String]> {
		return await read(.profileInterests(userId: userId), cachePolicy: cachePolicy)
	}

	func readProfileSocialMedia(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<UserSocialMediaDTO> {
		return await read(.profileSocialMedia(userId: userId), cachePolicy: cachePolicy)
	}

	func readProfileActivities(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[ProfileActivityDTO]> {
		return await read(.profileActivities(userId: userId), cachePolicy: cachePolicy)
	}
}
