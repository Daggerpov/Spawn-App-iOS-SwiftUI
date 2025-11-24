//
//  DataFetcher+Compatibility.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-24.
//
//  Backward compatibility layer for existing ViewModels using DataFetcher.
//  This allows for gradual migration to the new DataService architecture.
//
//  DEPRECATED: Use DataService instead of DataFetcher.
//  This compatibility layer will be removed in a future version.
//

import Foundation

// MARK: - Type Aliases for Backward Compatibility

/// @deprecated Use DataReader instead
typealias DataFetcher = DataReader

/// @deprecated Use IDataReader instead
typealias IDataFetcher = IDataReader

/// @deprecated Use DataResult instead
typealias FetchResult<T> = DataResult<T>

// MARK: - Compatibility Extensions

extension DataReader {
	/// @deprecated Use read() instead
	func fetch<T: Decodable>(
		_ dataType: DataType,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<T> {
		return await read(dataType, cachePolicy: cachePolicy)
	}

	/// @deprecated Use readActivities() instead
	func fetchActivities(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[FullFeedActivityDTO]> {
		return await readActivities(userId: userId, cachePolicy: cachePolicy)
	}

	/// @deprecated Use readActivityTypes() instead
	func fetchActivityTypes(
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[ActivityTypeDTO]> {
		return await readActivityTypes(cachePolicy: cachePolicy)
	}

	/// @deprecated Use readFriends() instead
	func fetchFriends(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[FullFriendUserDTO]> {
		return await readFriends(userId: userId, cachePolicy: cachePolicy)
	}

	/// @deprecated Use readRecommendedFriends() instead
	func fetchRecommendedFriends(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[RecommendedFriendUserDTO]> {
		return await readRecommendedFriends(userId: userId, cachePolicy: cachePolicy)
	}

	/// @deprecated Use readFriendRequests() instead
	func fetchFriendRequests(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[FetchFriendRequestDTO]> {
		return await readFriendRequests(userId: userId, cachePolicy: cachePolicy)
	}

	/// @deprecated Use readSentFriendRequests() instead
	func fetchSentFriendRequests(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[FetchSentFriendRequestDTO]> {
		return await readSentFriendRequests(userId: userId, cachePolicy: cachePolicy)
	}

	/// @deprecated Use readProfileStats() instead
	func fetchProfileStats(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<UserStatsDTO> {
		return await readProfileStats(userId: userId, cachePolicy: cachePolicy)
	}

	/// @deprecated Use readProfileInterests() instead
	func fetchProfileInterests(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[String]> {
		return await readProfileInterests(userId: userId, cachePolicy: cachePolicy)
	}

	/// @deprecated Use readProfileSocialMedia() instead
	func fetchProfileSocialMedia(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<UserSocialMediaDTO> {
		return await readProfileSocialMedia(userId: userId, cachePolicy: cachePolicy)
	}

	/// @deprecated Use readProfileActivities() instead
	func fetchProfileActivities(
		userId: UUID,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<[ProfileActivityDTO]> {
		return await readProfileActivities(userId: userId, cachePolicy: cachePolicy)
	}
}
