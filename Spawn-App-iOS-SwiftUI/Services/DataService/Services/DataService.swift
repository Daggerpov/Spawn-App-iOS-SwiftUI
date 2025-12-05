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

/// Actor-based DataService for thread-safe data operations
/// Delegates to DataReader and DataWriter actors
actor DataService: IDataService {

	static let shared = DataService()

	private let reader: DataReader
	private let writer: DataWriter

	init(
		reader: DataReader = DataReader.shared,
		writer: DataWriter = DataWriter.shared
	) {
		self.reader = reader
		self.writer = writer
	}

	// MARK: - Read Operations

	/// Fetch data using a DataType configuration
	func read<T: Decodable & Sendable>(
		_ dataType: DataType,
		cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
	) async -> DataResult<T> {
		return await reader.read(dataType, cachePolicy: cachePolicy)
	}

	// MARK: - Write Operations

	/// Perform a write operation with a response body
	func write<RequestBody: Encodable & Sendable, Response: Decodable & Sendable>(
		_ operation: WriteOperation<RequestBody>,
		invalidateCache: Bool = true
	) async -> DataResult<Response> {
		return await writer.write(operation, invalidateCache: invalidateCache)
	}

	/// Perform a write operation without a response body
	func writeWithoutResponse<RequestBody: Encodable & Sendable>(
		_ operation: WriteOperation<RequestBody>,
		invalidateCache: Bool = true
	) async -> DataResult<EmptyResponse> {
		return await writer.writeWithoutResponse(operation, invalidateCache: invalidateCache)
	}
}
