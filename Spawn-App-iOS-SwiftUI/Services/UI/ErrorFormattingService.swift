//
//  ErrorFormattingService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 2025-01-22.
//

import Foundation

/// Service responsible for converting raw technical error messages into user-friendly text
/// Thread-safe singleton with no mutable state
final class ErrorFormattingService: Sendable {
	static let shared = ErrorFormattingService()

	private init() {}

	/// Converts any error into a user-friendly message suitable for display
	/// - Parameter error: The error to format
	/// - Returns: A user-friendly error message
	func formatError(_ error: Error) -> String {
		if let apiError = error as? APIError {
			return formatAPIError(apiError)
		}

		return formatGenericError(error.localizedDescription)
	}

	/// Formats API-specific errors with appropriate user messages
	/// - Parameter apiError: The API error to format
	/// - Returns: A user-friendly error message
	func formatAPIError(_ apiError: APIError) -> String {
		switch apiError {
		case .failedHTTPRequest:
			return "We're having trouble connecting to our servers. Please try again."
		case .invalidStatusCode(let statusCode):
			return formatStatusCodeError(statusCode)
		case .validationError(let message):
			return formatGenericError(message)
		case .failedJSONParsing:
			return "We're having trouble processing the server response. Please try again."
		case .invalidData:
			return "The information received from the server is invalid. Please try again."
		case .URLError:
			return "Unable to connect to the server. Please check your internet connection and try again."
		case .unknownError(let error):
			return formatGenericError(error.localizedDescription)
		case .failedTokenSaving:
			return "There was an issue with authentication. Please try signing in again."
		case .cancelled:
			return "Request was cancelled."  // This typically shouldn't be shown to users
		}
	}

	/// Formats HTTP status code errors into user-friendly messages
	/// - Parameter statusCode: The HTTP status code
	/// - Returns: A user-friendly error message
	private func formatStatusCodeError(_ statusCode: Int) -> String {
		switch statusCode {
		case 400:
			return "Please check your information and try again."
		case 401:
			return "Authentication failed. Please sign in again."
		case 403:
			return "You don't have permission to perform this action."
		case 404:
			return "The requested information could not be found."
		case 409:
			return "This information is already in use. Please try different details."
		case 429:
			return "Too many attempts. Please wait a few minutes and try again."
		case 500...599:
			return "We're experiencing technical difficulties. Please try again in a few moments."
		default:
			return "We're having trouble processing your request. Please try again."
		}
	}

	/// Formats generic error messages into user-friendly alternatives
	/// - Parameter rawMessage: The raw error message
	/// - Returns: A user-friendly error message
	func formatGenericError(_ rawMessage: String) -> String {
		let lowercased = rawMessage.lowercased()

		// Network-related errors
		if lowercased.contains("network") || lowercased.contains("connection") || lowercased.contains("timeout")
			|| lowercased.contains("unreachable")
		{
			return "Unable to connect to the server. Please check your internet connection and try again."
		}

		// Server errors
		if lowercased.contains("server") || lowercased.contains("internal") || lowercased.contains("500")
			|| lowercased.contains("503")
		{
			return "We're experiencing technical difficulties. Please try again in a few moments."
		}

		// Authentication errors
		if lowercased.contains("unauthorized") || lowercased.contains("401") || lowercased.contains("forbidden")
			|| lowercased.contains("403") || lowercased.contains("token") || lowercased.contains("auth")
		{
			return "Authentication failed. Please try signing in again."
		}

		// Validation errors
		if lowercased.contains("validation") || lowercased.contains("invalid") || lowercased.contains("format")
			|| lowercased.contains("required")
		{
			return "Please check your information and try again."
		}

		// Rate limiting
		if lowercased.contains("rate") || lowercased.contains("limit") || lowercased.contains("429")
			|| lowercased.contains("too many")
		{
			return "Too many attempts. Please wait a few minutes and try again."
		}

		// Conflict/duplicate errors
		if lowercased.contains("conflict") || lowercased.contains("duplicate") || lowercased.contains("already exists")
			|| lowercased.contains("409")
		{
			return "This information is already in use. Please try different details."
		}

		// Generic fallback - never show raw technical errors to users
		return "We're having trouble processing your request. Please try again."
	}

	/// Formats error messages specifically for onboarding flows with more context
	/// - Parameters:
	///   - error: The error to format
	///   - context: Additional context about where the error occurred (e.g., "account creation", "phone verification")
	/// - Returns: A contextual user-friendly error message
	func formatOnboardingError(_ error: Error, context: String) -> String {
		let baseMessage = formatError(error)

		// Add context-specific guidance for onboarding
		switch context.lowercased() {
		case "account creation", "registration":
			if baseMessage.contains("already in use") {
				return "\(baseMessage) If you already have an account, try signing in instead."
			}
		case "phone verification", "verification":
			return "We're having trouble verifying your phone number. Please check the number and try again."
		case "profile setup":
			if isNetworkRelatedMessage(baseMessage) || isAuthRelatedMessage(baseMessage) {
				return baseMessage
			}
			return "We're having trouble saving your profile information. Please check your details and try again."
		case "apple sign-in", "google sign-in", "sign in", "authentication":
			if isNetworkRelatedMessage(baseMessage) {
				return baseMessage
			}
			return "We're having trouble signing you in. Please try again."
		default:
			break
		}

		return baseMessage
	}

	private func isNetworkRelatedMessage(_ message: String) -> Bool {
		let lowercased = message.lowercased()
		return lowercased.contains("connect") || lowercased.contains("internet") || lowercased.contains("network")
	}

	private func isAuthRelatedMessage(_ message: String) -> Bool {
		let lowercased = message.lowercased()
		return lowercased.contains("sign in") || lowercased.contains("session") || lowercased.contains("authentication")
	}

	/// Formats error messages with resource and operation context
	/// - Parameters:
	///   - error: The error to format
	///   - resource: The type of resource being operated on (e.g., "activity", "friend")
	///   - operation: The operation that failed (e.g., "create", "update", "delete")
	/// - Returns: A contextual user-friendly error message
	func formatContextualError(_ error: Error, resource: String, operation: String) -> String {
		// First, get the base error classification
		if let apiError = error as? APIError {
			return formatContextualAPIError(apiError, resource: resource, operation: operation)
		}

		return formatGenericContextualError(error.localizedDescription, resource: resource, operation: operation)
	}

	/// Formats API errors with resource and operation context
	private func formatContextualAPIError(_ apiError: APIError, resource: String, operation: String) -> String {
		switch apiError {
		case .invalidStatusCode(let statusCode):
			return formatContextualStatusCode(statusCode, resource: resource, operation: operation)
		case .failedHTTPRequest:
			return "We're having trouble connecting to our servers. Please check your connection and try again."
		case .validationError(let message):
			return formatGenericContextualError(message, resource: resource, operation: operation)
		case .failedJSONParsing:
			return "We received unexpected data. Please try again."
		case .invalidData:
			return "The \(resource) information couldn't be processed. Please try again."
		case .URLError:
			return "Unable to connect. Please check your internet connection."
		case .unknownError(let error):
			return formatGenericContextualError(error.localizedDescription, resource: resource, operation: operation)
		case .failedTokenSaving:
			return "There was an authentication issue. Please try signing in again."
		case .cancelled:
			return "Request was cancelled."
		}
	}

	/// Formats HTTP status codes with resource and operation context
	private func formatContextualStatusCode(_ statusCode: Int, resource: String, operation: String) -> String {
		switch statusCode {
		case 400:
			return "Please check your \(resource) information and try again."
		case 401:
			return "Your session has expired. Please sign in again."
		case 403:
			return "You don't have permission to \(operation) this \(resource)."
		case 404:
			return "This \(resource) could not be found. It may have been removed."
		case 409:
			return formatConflictError(resource: resource, operation: operation)
		case 429:
			return "Too many attempts. Please wait a moment and try again."
		case 500...599:
			return "We're experiencing technical difficulties. Please try again shortly."
		default:
			return "We couldn't \(operation) the \(resource). Please try again."
		}
	}

	/// Formats 409 Conflict errors based on context
	private func formatConflictError(resource: String, operation: String) -> String {
		let lowercasedResource = resource.lowercased()

		if lowercasedResource.contains("friend") && operation == "send" {
			return "A friend request already exists with this user."
		} else if lowercasedResource.contains("activity") && operation == "join" {
			return "You're already a participant in this activity."
		} else if lowercasedResource.contains("tag") && operation == "create" {
			return "A tag with this name already exists."
		} else if lowercasedResource.contains("block") {
			return "This user is already blocked."
		} else if lowercasedResource.contains("profile") || lowercasedResource.contains("user") {
			return "This username or information is already in use."
		}

		return "This \(resource) already exists or conflicts with another."
	}

	/// Formats generic errors with resource and operation context
	private func formatGenericContextualError(_ rawMessage: String, resource: String, operation: String) -> String {
		let lowercased = rawMessage.lowercased()

		// Network-related errors
		if lowercased.contains("network") || lowercased.contains("connection") || lowercased.contains("timeout")
			|| lowercased.contains("unreachable")
		{
			return "Unable to connect. Please check your internet and try again."
		}

		// Server errors
		if lowercased.contains("server") || lowercased.contains("internal") || lowercased.contains("500")
			|| lowercased.contains("503")
		{
			return "We're experiencing technical difficulties. Please try again shortly."
		}

		// Default contextual message
		return "We couldn't \(operation) the \(resource). Please try again."
	}
}
