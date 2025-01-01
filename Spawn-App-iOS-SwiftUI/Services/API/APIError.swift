//
//  APIError.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation

enum APIError: Error {
	case failedHTTPRequest(description: String)
	case invalidStatusCode(statusCode: Int)
	case failedJSONParsing
	case invalidData
	case URLError
	case unknownError(error: Error)

	var errorDescription: String {
		switch self {
			case let .failedHTTPRequest(description): return "\(description)"
			case let .invalidStatusCode(statusCode): return "Invalid Status Code: \(statusCode)"
			case .failedJSONParsing: return "Failed to properly parse JSON received from request"
			case .invalidData: return "Invalid data"
			case .URLError: return "URL Error: Please check which URL you're trying to access, or if it's potentially down at the moment."
			case let .unknownError(error): return "An Unknown Error Occurred Fetching Data: \(error)"
		}
	}
}
