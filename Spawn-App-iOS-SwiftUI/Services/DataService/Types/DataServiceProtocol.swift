//
//  DataServiceProtocol.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-24.
//
//  Protocol defining the unified data service interface.
//  ViewModels should only depend on this protocol, not on APIService or AppCache directly.
//

import Foundation

// MARK: - Data Service Protocol

/// Unified protocol for data operations (read and write)
/// This is the only interface ViewModels should interact with
protocol IDataService: Sendable {

	// MARK: - Read Operations (GET)

	/// Fetch data using a DataType configuration
	func read<T: Decodable & Sendable>(
		_ dataType: DataType,
		cachePolicy: CachePolicy
	) async -> DataResult<T>

	// MARK: - Write Operations (POST, PUT, PATCH, DELETE)

	/// Perform a write operation with a request body
	func write<RequestBody: Encodable & Sendable, Response: Decodable & Sendable>(
		_ operation: WriteOperation<RequestBody>,
		invalidateCache: Bool
	) async -> DataResult<Response>

	/// Perform a write operation without a response body (e.g., DELETE)
	func writeWithoutResponse<RequestBody: Encodable & Sendable>(
		_ operation: WriteOperation<RequestBody>,
		invalidateCache: Bool
	) async -> DataResult<EmptyResponse>
}

// MARK: - Convenience Extensions

extension IDataService {

	// Convenience methods with default parameters

	func read<T: Decodable & Sendable>(
		_ dataType: DataType
	) async -> DataResult<T> {
		return await read(dataType, cachePolicy: .cacheFirst(backgroundRefresh: true))
	}

	func write<RequestBody: Encodable & Sendable, Response: Decodable & Sendable>(
		_ operation: WriteOperation<RequestBody>
	) async -> DataResult<Response> {
		return await write(operation, invalidateCache: true)
	}

	func writeWithoutResponse<RequestBody: Encodable & Sendable>(
		_ operation: WriteOperation<RequestBody>
	) async -> DataResult<EmptyResponse> {
		return await writeWithoutResponse(operation, invalidateCache: true)
	}
}
