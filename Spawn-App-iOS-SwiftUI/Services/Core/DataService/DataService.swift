//
//  DataService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-24.
//
//  Unified data service that combines DataReader and DataWriter.
//  This is the main interface ViewModels should use for all data operations.
//  It provides a clean abstraction over APIService and AppCache, following
//  the Repository pattern.
//

import Foundation

// MARK: - Data Service Implementation

/// Concrete implementation of IDataService that delegates to DataReader and DataWriter
class DataService: IDataService {

	static let shared = DataService()

	private let reader: IDataReader
	private let writer: IDataWriter

	init(
		reader: IDataReader = DataReader.shared,
		writer: IDataWriter = DataWriter.shared
	) {
		self.reader = reader
		self.writer = writer
	}

	// MARK: - Read Operations

	/// Fetch data using a DataType configuration
	func read<T: Decodable>(
		_ dataType: DataType,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<T> {
		return await reader.read(dataType, cachePolicy: cachePolicy)
	}

	// MARK: - Write Operations

	/// Perform a write operation with a response body
	func write<RequestBody: Encodable, Response: Decodable>(
		_ operation: WriteOperation<RequestBody>,
		invalidateCache: Bool = true
	) async -> DataResult<Response> {
		return await writer.write(operation, invalidateCache: invalidateCache)
	}

	/// Perform a write operation without a response body
	func writeWithoutResponse<RequestBody: Encodable>(
		_ operation: WriteOperation<RequestBody>,
		invalidateCache: Bool = true
	) async -> DataResult<EmptyResponse> {
		return await writer.writeWithoutResponse(operation, invalidateCache: invalidateCache)
	}
}

// MARK: - Convenience Extensions for Common Operations

extension DataService {

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
