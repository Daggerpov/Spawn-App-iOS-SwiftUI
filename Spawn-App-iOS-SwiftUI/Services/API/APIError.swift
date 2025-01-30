//
//  APIError.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation

enum APIError: LocalizedError {
	case failedHTTPRequest(description: String)
	case invalidStatusCode(statusCode: Int)
	case failedJSONParsing(url: URL)
	case invalidData
	case URLError
	case unknownError(error: Error)

	var errorDescription: String? {
		switch self {
			case let .failedHTTPRequest(description):
				return description
			case let .invalidStatusCode(statusCode):
				return "Invalid Status Code: \(statusCode)"
			case let .failedJSONParsing(url):
				return "Failed to properly parse JSON received from request to this url: \(url)"
			case .invalidData:
				return "Invalid data received."
			case .URLError:
				return "URL Error: Please check the URL or if the server is currently down."
			case let .unknownError(error):
				return "An unknown error occurred: \(error.localizedDescription)"
		}
	}
}
