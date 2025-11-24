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
//  Refactored to use configuration-based approach with DataType enum for better maintainability.
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
	/// Fetch data using a DataType configuration
	func fetch<T: Decodable>(
		_ dataType: DataType,
		cachePolicy: CachePolicy
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

	/// Generic fetch method using DataType configuration
	func fetch<T: Decodable>(
		_ dataType: DataType,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<T> {

		// Get cache operations for this data type
		guard let cacheOps = CacheOperationsFactory.operations(for: dataType, appCache: appCache) as CacheOperations<T>?
		else {
			print("❌ [DataFetcher] No cache operations found for \(dataType.displayName)")
			return .failure(DataFetcherError.unsupportedDataType)
		}

		let cacheKey = dataType.cacheKey

		switch cachePolicy {
		case .cacheOnly:
			// Only use cache, never fetch from API
			if let cachedData = cacheOps.provider() {
				print("✅ [DataFetcher] Using cached \(dataType.displayName)")
				return .success(cachedData, source: .cache)
			} else {
				print("⚠️ [DataFetcher] No cached \(dataType.displayName) available")
				return .failure(DataFetcherError.noCachedData)
			}

		case .apiOnly:
			// Always fetch from API, bypass cache
			print("🔄 [DataFetcher] Fetching \(dataType.displayName) from API (cache bypassed)")
			return await fetchFromAPI(dataType: dataType, cacheOps: cacheOps)

		case .cacheFirst(let backgroundRefresh):
			// Check cache first
			if let cachedData = cacheOps.provider() {
				print("✅ [DataFetcher] Using cached \(dataType.displayName)")

				// If background refresh is enabled, fetch from API in background
				if backgroundRefresh {
					Task {
						print("🔄 [DataFetcher] Refreshing \(dataType.displayName) in background")
						let _ = await fetchFromAPI(dataType: dataType, cacheOps: cacheOps)
					}
				}

				return .success(cachedData, source: .cache)
			} else {
				// No cached data, fetch from API
				print("🔄 [DataFetcher] No cached \(dataType.displayName), fetching from API")
				return await fetchFromAPI(dataType: dataType, cacheOps: cacheOps)
			}
		}
	}

	/// Internal method to fetch from API
	private func fetchFromAPI<T: Decodable>(
		dataType: DataType,
		cacheOps: CacheOperations<T>
	) async -> FetchResult<T> {

		// Build URL from endpoint
		guard let url = URL(string: APIService.baseURL + dataType.endpoint) else {
			print("❌ [DataFetcher] Invalid URL for \(dataType.displayName)")
			return .failure(DataFetcherError.invalidURL)
		}

		do {
			// Fetch from API
			let data: T = try await apiService.fetchData(
				from: url,
				parameters: dataType.parameters
			)

			// Update cache
			cacheOps.updater(data)

			print("✅ [DataFetcher] API fetch successful for \(dataType.displayName)")
			return .success(data, source: .api)

		} catch {
			print("❌ [DataFetcher] API fetch failed for \(dataType.displayName): \(error)")
			return .failure(error)
		}
	}
}

// MARK: - Data Fetcher Error

enum DataFetcherError: Error, LocalizedError {
	case noCachedData
	case unsupportedDataType
	case invalidURL
	case apiFailed(Error)

	var errorDescription: String? {
		switch self {
		case .noCachedData:
			return "No cached data available"
		case .unsupportedDataType:
			return "Unsupported data type configuration"
		case .invalidURL:
			return "Invalid API endpoint URL"
		case .apiFailed(let error):
			return "API fetch failed: \(error.localizedDescription)"
		}
	}
}

// MARK: - Convenience Extensions (Optional)

/// Optional convenience methods for common use cases
/// These are just wrappers around the generic fetch method for better discoverability
extension DataFetcher {

	// MARK: - Activities

	func fetchActivities(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[FullFeedActivityDTO]> {
		return await fetch(.activities(userId: userId), cachePolicy: cachePolicy)
	}

	func fetchActivityTypes(
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[ActivityTypeDTO]> {
		return await fetch(.activityTypes, cachePolicy: cachePolicy)
	}

	// MARK: - Friends

	func fetchFriends(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[FullFriendUserDTO]> {
		return await fetch(.friends(userId: userId), cachePolicy: cachePolicy)
	}

	func fetchRecommendedFriends(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[RecommendedFriendUserDTO]> {
		return await fetch(.recommendedFriends(userId: userId), cachePolicy: cachePolicy)
	}

	func fetchFriendRequests(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[FetchFriendRequestDTO]> {
		return await fetch(.friendRequests(userId: userId), cachePolicy: cachePolicy)
	}

	func fetchSentFriendRequests(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[FetchSentFriendRequestDTO]> {
		return await fetch(.sentFriendRequests(userId: userId), cachePolicy: cachePolicy)
	}

	// MARK: - Profile

	func fetchProfileStats(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<UserStatsDTO> {
		return await fetch(.profileStats(userId: userId), cachePolicy: cachePolicy)
	}

	func fetchProfileInterests(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[String]> {
		return await fetch(.profileInterests(userId: userId), cachePolicy: cachePolicy)
	}

	func fetchProfileSocialMedia(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<UserSocialMediaDTO> {
		return await fetch(.profileSocialMedia(userId: userId), cachePolicy: cachePolicy)
	}

	func fetchProfileActivities(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> FetchResult<[ProfileActivityDTO]> {
		return await fetch(.profileActivities(userId: userId), cachePolicy: cachePolicy)
	}
}
