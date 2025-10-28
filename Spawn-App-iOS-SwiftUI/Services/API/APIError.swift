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
	case failedTokenSaving(tokenType: String)
	case cancelled // New case for cancelled requests

	var errorDescription: String? {
		switch self {
		case let .failedHTTPRequest(description):
			return description
		case let .invalidStatusCode(statusCode):
			return "Invalid Status Code: \(statusCode)"
		case let .failedJSONParsing(url):
			return
				"Failed to properly parse JSON received from request to this url: \(url)"
		case .invalidData:
			return "Invalid data received."
		case .URLError:
			return
				"URL Error: Please check the URL or if the server is currently down."
		case let .unknownError(error):
			return "An unknown error occurred: \(error.localizedDescription)"
		case let .failedTokenSaving(tokenType):
			return "An error occurred saving the JWT (for \(tokenType)) to keychain."
		case .cancelled:
			return "Request was cancelled."
		}
	}
	
	/// Check if an error is a cancellation error
	static func isCancellation(_ error: Error) -> Bool {
		// Check for APIError.cancelled
		if let apiError = error as? APIError, case .cancelled = apiError {
			return true
		}
		
		// Check for URLError cancellation
		if let urlError = error as? URLError {
			return urlError.code == .cancelled
		}
		
		// Check for NSError with NSURLErrorDomain and code -999
		let nsError = error as NSError
		return nsError.domain == NSURLErrorDomain && nsError.code == -999
	}
	
	/// Conditionally print an error message if the error is NOT a cancellation.
	/// Use this in catch blocks to avoid logging expected cancellation errors.
	/// - Parameters:
	///   - error: The error to check and potentially log
	///   - message: The message to print before the error (default: "Error occurred")
	/// - Returns: true if the error was a cancellation (and not logged), false otherwise
	@discardableResult
	static func logIfNotCancellation(_ error: Error, message: String = "Error occurred") -> Bool {
		guard !isCancellation(error) else {
			return true // It was a cancellation
		}
		print("\(message): \(error)")
		return false // It was not a cancellation
	}
}
