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

		switch cachePolicy {
		case .cacheOnly:
			// Only use cache, never fetch from API
			if let cachedData = cacheOps.provider() {
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

				// If background refresh is enabled, fetch from API in background
				if backgroundRefresh {
					Task {
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

			return .success(data, source: .api)

		} catch {
			print("❌ [DataReader] API fetch failed for \(dataType.displayName): \(error)")
			return .failure(error)
		}
	}
}
