//
//  DataServiceTypes.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-24.
//
//  Core types and enums for the DataService architecture.
//  This file defines the common types used across DataReader and DataWriter.
//

import Foundation

// MARK: - HTTP Method

/// HTTP methods supported by the data service
enum HTTPMethod: String, Sendable {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case delete = "DELETE"
	case patch = "PATCH"

	var isReadOperation: Bool {
		return self == .get
	}

	var isWriteOperation: Bool {
		return !isReadOperation
	}
}

// MARK: - Cache Policy

/// Defines how the DataService should handle caching for read operations
enum CachePolicy: Sendable {
	/// Check cache first, if available use it and optionally refresh in background
	case cacheFirst(backgroundRefresh: Bool = true)
	/// Always fetch from API, bypass cache (but still update cache after fetch)
	case apiOnly
	/// Use only cache, never fetch from API
	case cacheOnly
}

// MARK: - Data Source

/// Indicates the source of data in a result
enum DataSource: Sendable {
	case cache
	case api
}

// MARK: - Data Operation Result

/// Result of a data operation (read or write)
/// Uses @unchecked Sendable because Error is not Sendable by default,
/// but in practice our errors are safe to pass across actor boundaries.
enum DataResult<T: Sendable>: @unchecked Sendable {
	case success(T, source: DataSource)
	case failure(Error)
}

// MARK: - Data Service Error

enum DataServiceError: Error, LocalizedError, Sendable {
	case noCachedData
	case unsupportedDataType
	case unsupportedOperation(HTTPMethod, String)
	case invalidURL
	case apiFailed(Error)
	case encodingFailed
	case missingRequestBody

	var errorDescription: String? {
		switch self {
		case .noCachedData:
			return "No cached data available"
		case .unsupportedDataType:
			return "Unsupported data type configuration"
		case .unsupportedOperation(let method, let dataType):
			return "Unsupported \(method.rawValue) operation for \(dataType)"
		case .invalidURL:
			return "Invalid API endpoint URL"
		case .apiFailed(let error):
			return "API operation failed: \(error.localizedDescription)"
		case .encodingFailed:
			return "Failed to encode request body"
		case .missingRequestBody:
			return "Request body is required for this operation"
		}
	}
}

// MARK: - Write Operation Configuration

/// Configuration for write operations (POST, PUT, PATCH, DELETE)
struct WriteOperationConfig<Body: Encodable & Sendable>: Sendable {
	let method: HTTPMethod
	let endpoint: String
	let body: Body?
	let parameters: [String: String]?
	let cacheInvalidationKeys: [String]  // Cache keys to invalidate after successful write

	init(
		method: HTTPMethod,
		endpoint: String,
		body: Body? = nil,
		parameters: [String: String]? = nil,
		cacheInvalidationKeys: [String] = []
	) {
		self.method = method
		self.endpoint = endpoint
		self.body = body
		self.parameters = parameters
		self.cacheInvalidationKeys = cacheInvalidationKeys
	}
}

// MARK: - No Request Body Type

/// Empty struct for operations that don't require a request body
struct NoBody: Encodable, Sendable {}
