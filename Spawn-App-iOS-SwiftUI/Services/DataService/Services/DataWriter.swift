//
//  DataWriter.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-24.
//
//  DataWriter handles write operations (POST, PUT, PATCH, DELETE) for the data service layer.
//  It abstracts away the API service and cache invalidation logic, providing a clean interface
//  for ViewModels to perform write operations without knowing the implementation details.
//

import Foundation

// MARK: - Data Writer Protocol

/// Protocol defining the DataWriter interface for write operations
@MainActor
protocol IDataWriter {
	/// Perform a write operation with a response body
	func write<RequestBody: Encodable & Sendable, Response: Decodable>(
		_ operation: WriteOperation<RequestBody>,
		invalidateCache: Bool
	) async -> DataResult<Response>

	/// Perform a write operation without a response body
	func writeWithoutResponse<RequestBody: Encodable & Sendable>(
		_ operation: WriteOperation<RequestBody>,
		invalidateCache: Bool
	) async -> DataResult<EmptyResponse>
}

// MARK: - Data Writer Implementation

/// Main actor-isolated DataWriter for thread-safe write operations
@MainActor
final class DataWriter: IDataWriter {
	static let shared = DataWriter()

	private let apiService: IAPIService
	private let appCache: AppCache

	init(apiService: IAPIService = APIService(), appCache: AppCache = AppCache.shared) {
		self.apiService = apiService
		self.appCache = appCache
	}

	/// Perform a write operation with a response body
	func write<RequestBody: Encodable & Sendable, Response: Decodable>(
		_ operation: WriteOperation<RequestBody>,
		invalidateCache: Bool = true
	) async -> DataResult<Response> {

		print("🔄 [DataWriter] Performing \(operation.method.rawValue) to \(operation.endpoint)")

		// Build URL from endpoint
		guard let url = URL(string: APIService.baseURL + operation.endpoint) else {
			print("❌ [DataWriter] Invalid URL for endpoint: \(operation.endpoint)")
			return .failure(DataServiceError.invalidURL)
		}

		do {
			// Perform the appropriate HTTP method
			let response: Response = try await performWrite(
				method: operation.method,
				url: url,
				body: operation.body,
				parameters: operation.parameters
			)

			// Invalidate cache if requested
			if invalidateCache {
				invalidateCacheKeys(operation.cacheInvalidationKeys)
			}

			return .success(response, source: .api)

		} catch {
			print("❌ [DataWriter] \(operation.method.rawValue) failed for \(operation.endpoint): \(error)")
			return .failure(DataServiceError.apiFailed(error))
		}
	}

	/// Perform a write operation without a response body
	func writeWithoutResponse<RequestBody: Encodable & Sendable>(
		_ operation: WriteOperation<RequestBody>,
		invalidateCache: Bool = true
	) async -> DataResult<EmptyResponse> {

		print("🔄 [DataWriter] Performing \(operation.method.rawValue) to \(operation.endpoint)")
		print("🔄 [DataWriter] Parameters: \(String(describing: operation.parameters))")

		// Build URL from endpoint
		guard let url = URL(string: APIService.baseURL + operation.endpoint) else {
			print("❌ [DataWriter] Invalid URL for endpoint: \(operation.endpoint)")
			return .failure(DataServiceError.invalidURL)
		}

		print("🔄 [DataWriter] Base URL: \(url.absoluteString)")

		do {
			// Perform the write operation
			try await performWriteWithoutResponse(
				method: operation.method,
				url: url,
				body: operation.body,
				parameters: operation.parameters
			)

			// Invalidate cache if requested
			if invalidateCache {
				invalidateCacheKeys(operation.cacheInvalidationKeys)
			}

			return .success(EmptyResponse(), source: .api)

		} catch {
			print("❌ [DataWriter] \(operation.method.rawValue) failed for \(operation.endpoint): \(error)")
			print("❌ [DataWriter] Error description: \(error.localizedDescription)")
			if let apiError = error as? APIError {
				print("❌ [DataWriter] APIError details: \(apiError)")
			}
			return .failure(DataServiceError.apiFailed(error))
		}
	}

	// MARK: - Private Helper Methods

	/// Perform a write operation with response
	private func performWrite<RequestBody: Encodable & Sendable, Response: Decodable>(
		method: HTTPMethod,
		url: URL,
		body: RequestBody?,
		parameters: [String: String]?
	) async throws -> Response {

		switch method {
		case .post:
			guard let body = body else {
				throw DataServiceError.missingRequestBody
			}
			// For POST, we need to handle optional response
			if let response: Response = try await apiService.sendData(body, to: url, parameters: parameters) {
				return response
			} else {
				// If no response body, throw error or return empty
				throw DataServiceError.apiFailed(APIError.invalidData)
			}

		case .put:
			guard let body = body else {
				throw DataServiceError.missingRequestBody
			}
			return try await apiService.updateData(body, to: url, parameters: parameters)

		case .patch:
			guard let body = body else {
				throw DataServiceError.missingRequestBody
			}
			return try await apiService.patchData(from: url, with: body)

		case .delete:
			throw DataServiceError.unsupportedOperation(.delete, "DELETE with response body not supported")

		case .get:
			throw DataServiceError.unsupportedOperation(.get, "GET should use DataReader")
		}
	}

	/// Perform a write operation without response
	private func performWriteWithoutResponse<RequestBody: Encodable & Sendable>(
		method: HTTPMethod,
		url: URL,
		body: RequestBody?,
		parameters: [String: String]?
	) async throws {

		switch method {
		case .delete:
			try await apiService.deleteData(from: url, parameters: parameters, object: body)

		case .post:
			// POST requests use sendData
			if let body = body {
				let _: EmptyResponse? = try await apiService.sendData(
					body, to: url, parameters: parameters)
			} else {
				let _: EmptyResponse? = try await apiService.sendData(
					EmptyRequestBody(), to: url, parameters: parameters)
			}

		case .put:
			// PUT requests use updateData (returns EmptyResponse for 204 No Content)
			if let body = body {
				let _: EmptyResponse = try await apiService.updateData(
					body, to: url, parameters: parameters)
			} else {
				let _: EmptyResponse = try await apiService.updateData(
					EmptyRequestBody(), to: url, parameters: parameters)
			}

		case .patch:
			// PATCH requests use patchData
			if let body = body {
				let _: EmptyResponse = try await apiService.patchData(from: url, with: body)
			} else {
				let _: EmptyResponse = try await apiService.patchData(from: url, with: EmptyRequestBody())
			}

		case .get:
			throw DataServiceError.unsupportedOperation(.get, "GET should use DataReader")
		}
	}

	/// Invalidate cache keys after a successful write operation
	private func invalidateCacheKeys(_ keys: [String]) {
		guard !keys.isEmpty else { return }

		print("🗑️ [DataWriter] Invalidating cache keys: \(keys.joined(separator: ", "))")

		// For now, we'll just log. In a more sophisticated implementation,
		// we would have a cache invalidation mechanism in AppCache
		// that could selectively clear or refresh specific cache keys.

		// Future enhancement: Add a method to AppCache like:
		// appCache.invalidateCacheKeys(keys)

		// For now, we can trigger a background refresh of affected data
		// by posting notifications or calling refresh methods
	}
}
