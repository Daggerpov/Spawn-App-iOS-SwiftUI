//
//  WriteOperation.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-24.
//
//  Configuration for write operations (POST, PUT, PATCH, DELETE).
//  This provides a type-safe way to define write operations with proper request bodies.
//

import Foundation

// MARK: - Type-Erased Encodable Wrapper

/// A type-erased wrapper for any Encodable value
/// This allows operations to carry bodies of different types through a uniform interface
struct AnyEncodable: Encodable, Sendable {
	private let _encode: @Sendable (Encoder) throws -> Void

	init<T: Encodable & Sendable>(_ value: T) {
		self._encode = { encoder in
			try value.encode(to: encoder)
		}
	}

	func encode(to encoder: Encoder) throws {
		try _encode(encoder)
	}
}

// MARK: - Write Operation

/// Configuration for a write operation
struct WriteOperation<Body: Encodable & Sendable>: Sendable {
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

// MARK: - Convenience Constructors

extension WriteOperation {

	/// Create a POST operation
	static func post(
		endpoint: String,
		body: Body,
		parameters: [String: String]? = nil,
		cacheInvalidationKeys: [String] = []
	) -> WriteOperation<Body> {
		return WriteOperation(
			method: .post,
			endpoint: endpoint,
			body: body,
			parameters: parameters,
			cacheInvalidationKeys: cacheInvalidationKeys
		)
	}

	/// Create a PUT operation
	static func put(
		endpoint: String,
		body: Body,
		parameters: [String: String]? = nil,
		cacheInvalidationKeys: [String] = []
	) -> WriteOperation<Body> {
		return WriteOperation(
			method: .put,
			endpoint: endpoint,
			body: body,
			parameters: parameters,
			cacheInvalidationKeys: cacheInvalidationKeys
		)
	}

	/// Create a PATCH operation
	static func patch(
		endpoint: String,
		body: Body,
		parameters: [String: String]? = nil,
		cacheInvalidationKeys: [String] = []
	) -> WriteOperation<Body> {
		return WriteOperation(
			method: .patch,
			endpoint: endpoint,
			body: body,
			parameters: parameters,
			cacheInvalidationKeys: cacheInvalidationKeys
		)
	}

	/// Create a DELETE operation
	static func delete(
		endpoint: String,
		body: Body? = nil,
		parameters: [String: String]? = nil,
		cacheInvalidationKeys: [String] = []
	) -> WriteOperation<Body> {
		return WriteOperation(
			method: .delete,
			endpoint: endpoint,
			body: body,
			parameters: parameters,
			cacheInvalidationKeys: cacheInvalidationKeys
		)
	}
}

// MARK: - Write Operation Factory

/// Factory for creating common write operations using DataType configurations
struct WriteOperationFactory {

	/// Create a write operation from a DataType
	/// This allows DataType to also configure common write operations
	static func operation<Body: Encodable & Sendable>(
		for dataType: DataType,
		method: HTTPMethod,
		body: Body? = nil,
		parameters: [String: String]? = nil
	) -> WriteOperation<Body> {

		// Determine which cache keys to invalidate based on the data type
		let cacheKeys = [dataType.cacheKey]

		return WriteOperation(
			method: method,
			endpoint: dataType.endpoint,
			body: body,
			parameters: parameters ?? dataType.parameters,
			cacheInvalidationKeys: cacheKeys
		)
	}
}
