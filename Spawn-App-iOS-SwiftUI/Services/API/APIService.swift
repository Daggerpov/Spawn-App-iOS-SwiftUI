//
//  APIService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation
import Security
import UIKit

// Protocol to help handle Optional types in a generic way
protocol OptionalProtocol {
	static var nilValue: Self { get }
}

extension Optional: OptionalProtocol {
	static var nilValue: Self {
		return nil
	}
}

// MARK: - Error Response Structure
struct ErrorResponse: Codable {
	let message: String
}

final class APIService: IAPIService, @unchecked Sendable {
	/// Base URL for API requests. Uses nonisolated(unsafe) since it's set once at startup
	/// and read from multiple threads but not mutated during normal operation.
	nonisolated(unsafe) static var baseURL: String = ServiceConstants.URLs.apiBase

	var errorMessage: String?  // TODO: currently not being accessed; maybe use in alert to user
	var errorStatusCode: Int?  // if 404 -> just populate empty array, that's fine

	private func resetState() {
		errorMessage = nil
		errorStatusCode = nil
	}

	// Shared JSONDecoder for decoding data from the backend
	/// Note: not currently being used
	private static func makeDecoder() -> JSONDecoder {
		let decoder = JSONDecoder()

		// Custom date decoding strategy
		decoder.dateDecodingStrategy = .custom { decoder -> Date in
			let container = try decoder.singleValueContainer()
			let dateString = try container.decode(String.self)

			// Try ISO8601 with fractional seconds first
			let formatterWithFractional = ISO8601DateFormatter()
			formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

			if let date = formatterWithFractional.date(from: dateString) {
				return date
			}

			// Try ISO8601 without fractional seconds
			let formatterWithoutFractional = ISO8601DateFormatter()
			formatterWithoutFractional.formatOptions = [.withInternetDateTime]

			if let date = formatterWithoutFractional.date(from: dateString) {
				return date
			}

			// Try simple YYYY-MM-DD format (for CalendarActivityDTO)
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "yyyy-MM-dd"
			dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

			if let date = dateFormatter.date(from: dateString) {
				return date
			}

			// If all attempts fail, throw an error
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "Invalid date format: \(dateString)")
		}
		return decoder
	}

	// Shared JSONEncoder for encoding data to send to the backend
	/// Note: not currently being used
	private static func makeEncoder() -> JSONEncoder {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .custom { date, encoder in
			var container = encoder.singleValueContainer()

			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [.withInternetDateTime]  // Use standard ISO8601 without fractional seconds

			let dateString = formatter.string(from: date)
			try container.encode(dateString)
		}
		return encoder
	}

	internal func fetchData<T: Decodable>(
		from url: URL,
		parameters: [String: String]? = nil
	) async throws -> T where T: Decodable {
		resetState()

		// Check if user is authenticated for non-auth endpoints
		let urlString = url.absoluteString
		let isAuthEndpoint = urlString.contains("/auth/") || urlString.contains("/quick-sign-in")
		let isWhitelistedEndpoint =
			urlString.contains("/optional-details") || urlString.contains("/contacts/cross-reference")

		if !isAuthEndpoint && !isWhitelistedEndpoint {
			let isAuthenticated = await MainActor.run {
				UserAuthViewModel.shared.spawnUser != nil && UserAuthViewModel.shared.isLoggedIn
			}
			guard isAuthenticated else {
				print("❌ Cannot make API call to \(urlString): User is not logged in")
				throw APIError.invalidStatusCode(statusCode: 401)
			}
		}

		// Create a URLComponents object from the URL
		var urlComponents = URLComponents(
			url: url, resolvingAgainstBaseURL: false)

		// Add query items if parameters are provided
		if let parameters = parameters {
			urlComponents?.queryItems = parameters.map {
				URLQueryItem(name: $0.key, value: $0.value)
			}
		}

		// Ensure the URL is valid after adding query items
		guard let finalURL = urlComponents?.url else {
			errorMessage = "Invalid URL after adding query parameters"
			print(errorMessage ?? "no error message to log")
			throw APIError.URLError
		}
		var request = URLRequest(url: finalURL)
		request.httpMethod = "GET"
		setAuthHeader(request: &request)

		var (data, response): (Data, URLResponse)
		do {
			(data, response) = try await URLSession.shared.data(for: request)
		} catch {
			// Check if this is a cancellation error and handle silently
			if APIError.isCancellation(error) {
				// Return empty result for cancelled requests without logging
				if let emptyResult = emptyResult(for: T.self) {
					return emptyResult
				}
				throw APIError.cancelled
			}
			// Re-throw non-cancellation errors
			throw error
		}

		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(finalURL)"
			print(errorMessage ?? "no error message to log")
			throw APIError.failedHTTPRequest(
				description: "The HTTP request has failed.")
		}

		// Handle auth tokens if present
		try handleAuthTokens(from: httpResponse, for: finalURL)

		// Special handling for 404 in auth endpoints
		if httpResponse.statusCode == 404 {
			// If this is an auth endpoint and we get a 404, this likely means the user doesn't exist yet
			if finalURL.absoluteString.contains("/auth/") {
				errorStatusCode = 404
				throw APIError.invalidStatusCode(statusCode: 404)
			}

			// For non-auth endpoints, try to return an empty result
			if let emptyArrayResult = emptyArrayResult(for: T.self) {
				return emptyArrayResult
			}
		}

		// Check status code
		if httpResponse.statusCode == 401 {
			// Handle token refresh logic here
			let newAccessToken: String = try await handleRefreshToken()
			// Retry the request with the new access token
			data = try await retryRequest(request: &request, bearerAccessToken: newAccessToken)
		} else if httpResponse.statusCode != 200 {
			throw createAPIError(statusCode: httpResponse.statusCode, data: data)
		}

		// Handle empty responses
		if data.isEmpty || data.count == 0 {
			if let emptyResponse = emptyResult(for: T.self) {
				return emptyResponse
			}
			throw APIError.invalidData
		}

		// Create decoder outside the try/catch scope so it's accessible in all blocks
		let decoder = APIService.makeDecoder()

		// Try to decode normally first
		do {
			let decodedData = try decoder.decode(T.self, from: data)
			return decodedData
		} catch let decodingError {
			// If normal decoding fails and we're expecting a single object but got an array,
			// try to extract the first item from the array
			let isArrayType = String(describing: T.self).contains("Array")

			// Only attempt array handling if we're not already expecting an array type
			if !isArrayType {
				// Try to decode as an array of that type
				print(
					"Attempting to decode as array and extract the first item for entity type '\(T.self)' from URL: \(finalURL)"
				)

				do {
					// Use JSONSerialization first to check if it's an array
					if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [Any],
						!jsonObject.isEmpty
					{

						// It is an array, try to decode it as such and take the first element
						if let firstItemData = try? JSONSerialization.data(withJSONObject: jsonObject[0]) {
							let firstItem = try decoder.decode(T.self, from: firstItemData)
							print("Successfully decoded first item from array response")
							return firstItem
						}
					}
				} catch {
					print("Failed to extract first item from array: \(error)")
				}
			}

			// If we got here, throw the original decoding error
			print("JSON Decoding Error: \(decodingError)")
			if let jsonString = String(data: data, encoding: .utf8) {
				print("Received JSON: \(jsonString)")
			}
			throw APIError.failedJSONParsing(url: finalURL)
		}
	}

	internal func sendData<T: Encodable, U: Decodable>(
		_ object: T,
		to url: URL,
		parameters: [String: String]? = nil
	) async throws -> U? {
		resetState()

		// Check if user is authenticated for non-auth endpoints
		let urlString = url.absoluteString
		let isAuthEndpoint = urlString.contains("/auth/") || urlString.contains("/quick-sign-in")
		let isWhitelistedEndpoint =
			urlString.contains("/optional-details") || urlString.contains("/contacts/cross-reference")

		if !isAuthEndpoint && !isWhitelistedEndpoint {
			let (isAuthenticated, spawnUserId, isLoggedIn) = await MainActor.run {
				(
					UserAuthViewModel.shared.spawnUser != nil && UserAuthViewModel.shared.isLoggedIn,
					UserAuthViewModel.shared.spawnUser?.id.uuidString,
					UserAuthViewModel.shared.isLoggedIn
				)
			}
			guard isAuthenticated else {
				print("❌ Cannot make API call to \(urlString): User is not logged in")

				// DEBUG: Extra logging for blocking endpoints
				if urlString.contains("blocked-users") {
					print("🚫 DEBUG: ❌ CRITICAL - User not logged in when attempting to block user!")
					print("🚫 DEBUG: spawnUser: \(spawnUserId ?? "nil")")
					print("🚫 DEBUG: isLoggedIn: \(isLoggedIn)")
				}

				throw APIError.invalidStatusCode(statusCode: 401)
			}
		}

		// Create a URLComponents object from the URL
		var urlComponents = URLComponents(
			url: url, resolvingAgainstBaseURL: false)

		// Add query items if parameters are provided
		if let parameters = parameters {
			urlComponents?.queryItems = parameters.map {
				URLQueryItem(name: $0.key, value: $0.value)
			}
		}

		// Ensure the URL is valid after adding query items
		guard let finalURL = urlComponents?.url else {
			errorMessage = "Invalid URL after adding query parameters"
			print(errorMessage ?? "no error message to log")
			throw APIError.URLError
		}

		let encoder = APIService.makeEncoder()
		let encodedData = try encoder.encode(object)

		var request = URLRequest(url: finalURL)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = encodedData
		setAuthHeader(request: &request)

		let (data, response): (Data, URLResponse)
		do {
			(data, response) = try await URLSession.shared.data(for: request)
		} catch {
			// Check if this is a cancellation error and handle silently
			if APIError.isCancellation(error) {
				// Return nil for cancelled POST requests without logging
				return nil
			}
			// Re-throw non-cancellation errors
			throw error
		}

		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(finalURL)"
			print(errorMessage ?? "no error message to log")
			throw APIError.failedHTTPRequest(
				description: "The HTTP request has failed.")
		}

		// 200 means success || 201 means created || 204 means no content (successful operation with no response body)
		guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 204
		else {
			if httpResponse.statusCode == 401
				&& !(urlString.contains("/auth/sign-in") || urlString.contains("/auth/login"))
			{
				// DEBUG: Log for blocking endpoints specifically
				if urlString.contains("blocked-users") {
					print("🚫 DEBUG: Received 401 for blocking request, attempting token refresh...")
				}

				// Handle token refresh logic here
				do {
					let newAccessToken: String = try await handleRefreshToken()
					// Retry the request with the new access token
					let newData = try await retryRequest(request: &request, bearerAccessToken: newAccessToken)

					// DEBUG: Log for blocking endpoints specifically
					if urlString.contains("blocked-users") {
						print("🚫 DEBUG: ✅ Token refresh successful, blocking request retried")
					}

					return try APIService.makeDecoder().decode(U.self, from: newData)
				} catch {
					// DEBUG: Log for blocking endpoints specifically
					if urlString.contains("blocked-users") {
						print("🚫 DEBUG: ❌ Token refresh failed for blocking request: \(error)")
					}
					throw error
				}
			}

			// DEBUG: Log for blocking endpoints specifically
			if urlString.contains("blocked-users") {
				print("🚫 DEBUG: ❌ Blocking request failed with status code: \(httpResponse.statusCode)")
			}

			throw createAPIError(statusCode: httpResponse.statusCode, data: data)
		}
		// Handle auth tokens if present
		try handleAuthTokens(from: httpResponse, for: finalURL)

		// Handle 204 No Content response
		if httpResponse.statusCode == 204 {
			// For 204 responses, return an EmptyResponse if that's what's expected
			if U.self == EmptyResponse.self {
				return EmptyResponse() as? U
			}
			// For optional types, return nil
			return nil
		}
		if !data.isEmpty {
			// When expecting EmptyResponse (e.g. writeWithoutResponse), backend may return 200/201 with a body
			// (e.g. POST interests returns 201 with the interest name string). Treat as success without decoding.
			if U.self == EmptyResponse.self {
				return EmptyResponse() as? U
			}
			do {
				let decoder = APIService.makeDecoder()
				let decodedData = try decoder.decode(U.self, from: data)
				return decodedData
			} catch {
				errorMessage =
					APIError.failedJSONParsing(url: finalURL)
					.localizedDescription
				print(errorMessage ?? "no error message to log")
				throw APIError.failedJSONParsing(url: finalURL)
			}
		}

		return nil
	}

	internal func updateData<T: Encodable, R: Decodable>(
		_ object: T,
		to url: URL,
		parameters: [String: String]? = nil  // Add parameters here
	) async throws -> R {
		resetState()

		// Create a URLComponents object from the URL
		var urlComponents = URLComponents(
			url: url, resolvingAgainstBaseURL: false)

		// Add query items if parameters are provided
		if let parameters = parameters {
			urlComponents?.queryItems = parameters.map {
				URLQueryItem(name: $0.key, value: $0.value)
			}
		}

		// Ensure the URL is valid after adding query items
		guard let finalURL = urlComponents?.url else {
			errorMessage = "Invalid URL after adding query parameters"
			print(errorMessage ?? "no error message to log")
			throw APIError.URLError
		}

		let encoder = APIService.makeEncoder()
		let encodedData = try encoder.encode(object)

		var request = URLRequest(url: finalURL)
		request.httpMethod = "PUT"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = encodedData
		setAuthHeader(request: &request)

		let (data, response): (Data, URLResponse)
		do {
			(data, response) = try await URLSession.shared.data(for: request)
		} catch {
			// Check if this is a cancellation error and handle silently
			if APIError.isCancellation(error) {
				// For cancelled PUT requests, throw the cancellation error silently
				throw APIError.cancelled
			}
			// Re-throw non-cancellation errors
			throw error
		}

		guard let httpResponse = response as? HTTPURLResponse else {
			let message = "HTTP request failed for \(finalURL)"
			print(message)
			throw APIError.failedHTTPRequest(description: message)
		}

		guard httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
			if httpResponse.statusCode == 401 {
				// Handle token refresh logic here
				let newAccessToken: String = try await handleRefreshToken()
				// Retry the request with the new access token
				let newData = try await retryRequest(request: &request, bearerAccessToken: newAccessToken)
				return try APIService.makeDecoder().decode(R.self, from: newData)
			}
			errorStatusCode = httpResponse.statusCode
			let message =
				"Invalid status code \(httpResponse.statusCode) for \(finalURL)"
			print(message)
			throw APIError.invalidStatusCode(
				statusCode: httpResponse.statusCode)
		}

		// Handle 204 No Content response
		if httpResponse.statusCode == 204 {
			// For 204 responses, return an EmptyResponse if that's what's expected
			if R.self == EmptyResponse.self {
				return EmptyResponse() as! R
			}
			// This shouldn't happen for updateData since it should always return a decoded object
			throw APIError.invalidData
		}

		// Decode the response into the expected type `R`
		let decoder = APIService.makeDecoder()
		return try decoder.decode(R.self, from: data)
	}

	internal func deleteData<T: Encodable>(from url: URL, parameters: [String: String]? = nil, object: T?) async throws
	{
		resetState()

		// Build final URL with query parameters if present
		var finalUrl = url
		if let parameters = parameters, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
			components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
			guard let urlWithParams = components.url else {
				errorMessage = "Invalid URL after adding query parameters"
				print(errorMessage ?? "no error message to log")
				throw APIError.URLError
			}
			finalUrl = urlWithParams
			print("🔓 [APIService] DELETE URL with parameters: \(finalUrl.absoluteString)")
		} else {
			print("🔓 [APIService] DELETE URL (no parameters): \(finalUrl.absoluteString)")
		}

		var request = URLRequest(url: finalUrl)
		request.httpMethod = "DELETE"
		setAuthHeader(request: &request)

		if let object = object {
			let encoder = APIService.makeEncoder()
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.httpBody = try encoder.encode(object)
			print("🔓 [APIService] DELETE with body")
		} else {
			print("🔓 [APIService] DELETE without body")
		}

		let response: URLResponse
		do {
			(_, response) = try await URLSession.shared.data(for: request)
		} catch {
			// Check if this is a cancellation error and handle silently
			if APIError.isCancellation(error) {
				// For cancelled DELETE requests, just return without logging
				return
			}
			print("🔓 [APIService] DELETE request failed with error: \(error)")
			print("🔓 [APIService] Error details: \(error.localizedDescription)")
			// Re-throw non-cancellation errors
			throw error
		}

		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(url)"
			print(errorMessage ?? "no error message to log")
			throw APIError.failedHTTPRequest(
				description: "The HTTP request has failed.")
		}

		print("🔓 [APIService] DELETE response status code: \(httpResponse.statusCode)")

		// Check for a successful status code (204 is commonly used for successful deletions)
		guard httpResponse.statusCode == 204 || httpResponse.statusCode == 200
		else {
			if httpResponse.statusCode == 401 {
				// Handle token refresh logic here
				let newAccessToken: String = try await handleRefreshToken()
				// Retry the request with the new access token
				_ = try await retryRequest(request: &request, bearerAccessToken: newAccessToken)
				return
			}
			errorStatusCode = httpResponse.statusCode
			errorMessage =
				"invalid status code \(httpResponse.statusCode) for \(url)"
			print(errorMessage ?? "no error message to log")
			throw APIError.invalidStatusCode(
				statusCode: httpResponse.statusCode)
		}
	}

	func createUser(
		userDTO: UserCreateDTO, profilePicture: UIImage?,
		parameters: [String: String]?
	) async throws -> BaseUserDTO {
		resetState()

		// Create URL with parameters
		guard let baseURL = URL(string: APIService.baseURL + "auth/make-user")
		else {
			throw APIError.URLError
		}

		var urlComponents = URLComponents(
			url: baseURL, resolvingAgainstBaseURL: false)
		if let parameters = parameters {
			urlComponents?.queryItems = parameters.map {
				URLQueryItem(name: $0.key, value: $0.value)
			}
		}

		guard let finalURL = urlComponents?.url else {
			throw APIError.URLError
		}

		// Create the user creation DTO
		var userCreationDTO: [String: Any] = [
			"username": userDTO.username,
			"name": userDTO.name,
			"email": userDTO.email,
		]

		// Add profile picture data if available
		if let image = profilePicture {
			// Use higher compression quality and ensure we're getting a valid image
			if let imageData = image.jpegData(compressionQuality: 0.9) {
				let base64String = imageData.base64EncodedString()
				userCreationDTO["profilePictureData"] = base64String
				print("Including profile picture data of size: \(imageData.count) bytes")
			} else if let pngData = image.pngData() {
				// Try PNG as a fallback
				let base64String = pngData.base64EncodedString()
				userCreationDTO["profilePictureData"] = base64String
				print("Including PNG profile picture data of size: \(pngData.count) bytes")
			}
		} else if let profilePicUrl = parameters?["profilePicUrl"], !profilePicUrl.isEmpty {
			// If we have a URL from Google/Apple but no selected image, include it
			// Try both field names that the backend might be expecting
			userCreationDTO["profilePictureUrl"] = profilePicUrl
			userCreationDTO["profilePicture"] = profilePicUrl  // Try this field name as well
			print("Including profile picture URL from provider: \(profilePicUrl)")

			// Try to download the image from the URL and convert to base64
			if let url = URL(string: profilePicUrl) {
				do {
					let (data, _) = try await URLSession.shared.data(from: url)
					let base64String = data.base64EncodedString()
					userCreationDTO["profilePictureData"] = base64String
					print("Successfully downloaded and included Google profile picture data: \(data.count) bytes")
				} catch {
					print("Failed to download Google profile picture: \(error.localizedDescription)")
				}
			}
		}

		// Convert the DTO to JSON data
		guard let jsonData = try? JSONSerialization.data(withJSONObject: userCreationDTO) else {
			throw APIError.invalidData
		}

		// Create the request
		var request = URLRequest(url: finalURL)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = jsonData

		// Perform the request
		let (data, response): (Data, URLResponse)
		do {
			(data, response) = try await URLSession.shared.data(for: request)
		} catch {
			// Check if this is a cancellation error and handle silently
			if APIError.isCancellation(error) {
				throw APIError.cancelled
			}
			// Re-throw non-cancellation errors
			throw error
		}

		// Check the HTTP response
		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIError.failedHTTPRequest(description: "HTTP request failed")
		}

		// Check for success - 200 OK or 201 Created
		guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
			errorStatusCode = httpResponse.statusCode
			throw createAPIError(statusCode: httpResponse.statusCode, data: data)
		}

		// Parse the response
		let decoder = JSONDecoder()
		return try decoder.decode(BaseUserDTO.self, from: data)
	}

	private func handleAuthTokens(from response: HTTPURLResponse, for url: URL)
		throws
	{
		// Only process responses that actually contain auth tokens in headers.
		// The backend returns new tokens (e.g. after username change) via
		// Authorization and X-Refresh-Token headers on any endpoint that
		// requires token rotation, not just auth endpoints.
		guard
			response.allHeaderFields["Authorization"] as? String != nil
				|| response.allHeaderFields["authorization"] as? String != nil
		else {
			return
		}

		// Extract access token
		guard
			let accessToken = response.allHeaderFields["Authorization"] as? String ?? response.allHeaderFields[
				"authorization"] as? String
		else {
			print("⚠️ WARNING: No access token found in response headers")
			return
		}

		// Extract refresh token
		let refreshToken =
			response.allHeaderFields["X-Refresh-Token"] as? String ?? response.allHeaderFields["x-refresh-token"]
			as? String

		if refreshToken == nil {
			print("⚠️ WARNING: No refresh token found in response headers")
			// Don't throw error here - some endpoints might only return access tokens
		}

		// Remove "Bearer " prefix from access token
		let cleanAccessToken = accessToken.replacingOccurrences(of: "Bearer ", with: "")

		// Store access token in keychain with retry logic
		if let accessTokenData = cleanAccessToken.data(using: .utf8) {
			var saveAttempts = 0
			let maxSaveAttempts = 3
			var saveSuccessful = false

			while saveAttempts < maxSaveAttempts && !saveSuccessful {
				saveSuccessful = KeychainService.shared.save(key: "accessToken", data: accessTokenData)
				if !saveSuccessful {
					saveAttempts += 1
					print("⚠️ Access token save attempt \(saveAttempts) failed")
					if saveAttempts < maxSaveAttempts {
						// Brief delay before retry
						Thread.sleep(forTimeInterval: 0.1)
					}
				}
			}

			if !saveSuccessful {
				print("❌ ERROR: Failed to save access token to keychain after \(maxSaveAttempts) attempts")
				throw APIError.failedTokenSaving(tokenType: "accessToken")
			}
		}

		// Store refresh token if present
		if let refreshToken = refreshToken,
			let refreshTokenData = refreshToken.data(using: .utf8)
		{
			var saveAttempts = 0
			let maxSaveAttempts = 3
			var saveSuccessful = false

			while saveAttempts < maxSaveAttempts && !saveSuccessful {
				saveSuccessful = KeychainService.shared.save(key: "refreshToken", data: refreshTokenData)
				if !saveSuccessful {
					saveAttempts += 1
					print("⚠️ Refresh token save attempt \(saveAttempts) failed")
					if saveAttempts < maxSaveAttempts {
						// Brief delay before retry
						Thread.sleep(forTimeInterval: 0.1)
					}
				}
			}

			if !saveSuccessful {
				print("❌ ERROR: Failed to save refresh token to keychain after \(maxSaveAttempts) attempts")
				throw APIError.failedTokenSaving(tokenType: "refreshToken")
			}
		}
	}

	fileprivate func setAuthHeader(request: inout URLRequest) {
		guard let url = request.url else {
			print("❌ ERROR: URL is nil")
			return
		}

		// Check if auth headers are needed
		let whitelistedEndpoints = [
			"auth/register/verification/send",
			"auth/register/oauth",
			"auth/register/verification/check",
			"auth/sign-in",
			"auth/login",
			"optional-details",
			"contacts/cross-reference",
		]
		if whitelistedEndpoints.contains(where: { url.absoluteString.contains($0) }) {
			// Don't set auth headers for these endpoints
			return
		}

		// DEBUG: Log for blocking endpoints specifically
		if url.absoluteString.contains("blocked-users") {
			print("🚫 DEBUG: Setting auth header for blocking endpoint: \(url.absoluteString)")
		}

		// Get the access token from keychain
		guard
			let accessTokenData = KeychainService.shared.load(key: "accessToken"),
			let accessToken = String(data: accessTokenData, encoding: .utf8)
		else {
			print("⚠️ Missing access token for authenticated endpoint: \(url.absoluteString)")

			// DEBUG: Extra logging for blocking endpoints
			if url.absoluteString.contains("blocked-users") {
				print("🚫 DEBUG: ❌ CRITICAL - No access token available for blocking request!")
			}

			// Check if we have a refresh token available
			if let refreshTokenData = KeychainService.shared.load(key: "refreshToken"),
				String(data: refreshTokenData, encoding: .utf8) != nil
			{
				// We have a refresh token, but we'll let the API call handle the refresh
				// This will happen in the 401 handler in fetchData/sendData methods
				print("🔄 Missing access token but refresh token exists - will refresh during API call")
			} else {
				print("❌ ERROR: Missing both access token and refresh token in Keychain")
				print("🔄 Will let API call fail and higher-level error handling manage re-authentication")
				// Don't immediately sign out - let the API call fail and higher-level error handling
				// manage re-authentication. This preserves OAuth credentials during onboarding.
			}
			return
		}

		// DEBUG: Log for blocking endpoints specifically
		if url.absoluteString.contains("blocked-users") {
			print("🚫 DEBUG: ✅ Successfully set Authorization header for blocking request")
		}

		// Set the auth headers
		request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
	}

	internal func patchData<T: Encodable, U: Decodable>(
		from url: URL,
		with object: T
	) async throws -> U {
		resetState()

		let encoder = APIService.makeEncoder()
		let encodedData = try encoder.encode(object)

		// Debug: Log the request details
		print("🔍 PATCH REQUEST: \(url.absoluteString)")
		print("🔍 REQUEST BODY: \(String(data: encodedData, encoding: .utf8) ?? "Unable to convert to string")")

		var request = URLRequest(url: url)
		request.httpMethod = "PATCH"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = encodedData
		setAuthHeader(request: &request)

		let (data, response): (Data, URLResponse)
		do {
			(data, response) = try await URLSession.shared.data(for: request)
		} catch {
			// Check if this is a cancellation error and handle silently
			if APIError.isCancellation(error) {
				// For cancelled PATCH requests, throw the cancellation error silently
				throw APIError.cancelled
			}
			// Re-throw non-cancellation errors
			throw error
		}

		// Debug: Log the response details
		print("🔍 RESPONSE: \(response)")
		print("🔍 RESPONSE DATA: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")

		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(url)"
			print("❌ ERROR: HTTP request failed for \(url)")
			throw APIError.failedHTTPRequest(
				description: "The HTTP request has failed.")
		}

		guard httpResponse.statusCode == 200 else {
			if httpResponse.statusCode == 401 {
				let newAccessToken: String = try await handleRefreshToken()
				let newData = try await retryRequest(request: &request, bearerAccessToken: newAccessToken)
				return try APIService.makeDecoder().decode(U.self, from: newData)
			}

			errorMessage =
				"invalid status code \(httpResponse.statusCode) for \(url)"
			print("❌ ERROR: Invalid status code \(httpResponse.statusCode) for \(url)")

			if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
				print("❌ ERROR DETAILS: \(errorJson)")

				if httpResponse.statusCode == 400,
					let message = errorJson["message"] as? String
				{
					throw APIError.validationError(message: message)
				}
			}

			throw APIError.invalidStatusCode(
				statusCode: httpResponse.statusCode)
		}

		try handleAuthTokens(from: httpResponse, for: url)

		do {
			let decoder = APIService.makeDecoder()
			let decodedData = try decoder.decode(U.self, from: data)
			return decodedData
		} catch let apiError as APIError {
			throw apiError
		} catch {
			errorMessage =
				APIError.failedJSONParsing(url: url).localizedDescription
			print("❌ ERROR: JSON parsing failed for \(url): \(error)")

			print(
				"❌ DATA THAT FAILED TO PARSE: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")

			throw APIError.failedJSONParsing(url: url)
		}
	}

	// Helper to create empty results of the appropriate type
	private func emptyResult<T>(for type: T.Type) -> T? {
		// For array types
		if type is [Any].Type || type is [[String: Any]].Type {
			return [] as? T
		}

		// For optional types
		if let optionalType = type as? OptionalProtocol.Type {
			return optionalType.nilValue as? T
		}

		return nil
	}

	// Helper specifically for empty arrays
	private func emptyArrayResult<T>(for type: T.Type) -> T? {
		if type is [Any].Type || type is [[String: Any]].Type {
			return [] as? T
		}

		// For single objects, we can't create an empty result so return nil
		return nil
	}

	func updateProfilePicture(_ imageData: Data, userId: UUID) async throws -> BaseUserDTO {
		guard let url = URL(string: APIService.baseURL + "users/\(userId)/profile-picture") else {
			print("❌ ERROR: Failed to create URL for profile picture update")
			throw APIError.URLError
		}

		print("🔍 UPDATING PROFILE PICTURE: Starting request to \(url.absoluteString)")
		print("🔍 REQUEST DATA SIZE: \(imageData.count) bytes")

		// Create the request
		var request = URLRequest(url: url)
		request.httpMethod = "PATCH"
		request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
		request.httpBody = imageData
		setAuthHeader(request: &request)  // Set auth headers if needed
		// Log request headers
		print("🔍 REQUEST HEADERS: \(request.allHTTPHeaderFields ?? [:])")

		// Perform the request with detailed logging
		let (data, response): (Data, URLResponse)
		do {
			(data, response) = try await URLSession.shared.data(for: request)
		} catch {
			// Check if this is a cancellation error and handle silently
			if APIError.isCancellation(error) {
				throw APIError.cancelled
			}
			// Re-throw non-cancellation errors
			throw error
		}

		print("🔍 RESPONSE RECEIVED: \(response)")

		// Check if we can read the response as JSON or text
		if let responseString = String(data: data, encoding: .utf8) {
			print("🔍 RESPONSE DATA: \(responseString)")
		} else {
			print("🔍 RESPONSE DATA: Unable to convert to string (binary data of \(data.count) bytes)")
		}

		// Check the HTTP response
		guard let httpResponse = response as? HTTPURLResponse else {
			print("❌ ERROR: Failed HTTP request - unable to get HTTP response")
			throw APIError.failedHTTPRequest(description: "HTTP request failed")
		}

		guard (200...299).contains(httpResponse.statusCode) else {
			if httpResponse.statusCode == 401 {
				// Handle token refresh logic here
				let newAccessToken: String = try await handleRefreshToken()
				// Retry the request with the new access token
				let newData = try await retryRequest(request: &request, bearerAccessToken: newAccessToken)
				return try JSONDecoder().decode(BaseUserDTO.self, from: newData)
			}
			print("❌ ERROR: Invalid status code \(httpResponse.statusCode)")

			// Try to parse error details
			if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
				print("❌ ERROR DETAILS: \(errorJson)")
			}

			throw APIError.invalidStatusCode(statusCode: httpResponse.statusCode)
		}

		// Parse the response
		do {
			let decoder = JSONDecoder()
			let updatedUser = try decoder.decode(BaseUserDTO.self, from: data)
			return updatedUser
		} catch {
			print("❌ ERROR: Failed to decode user data after profile picture update: \(error)")
			print(
				"❌ DATA THAT FAILED TO PARSE: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
			throw APIError.failedJSONParsing(url: url)
		}
	}

	// Add sendMultipartFormData implementation
	func sendMultipartFormData(_ formData: [String: Any], to url: URL) async throws -> Data {
		resetState()

		let boundary = "Boundary-\(UUID().uuidString)"

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
		setAuthHeader(request: &request)  // Set auth headers if needed
		// Create the body
		var body = Data()

		for (key, value) in formData {
			if let data = value as? Data {
				// Handle image data
				if let boundaryData = "\r\n--\(boundary)\r\n".data(using: .utf8),
					let contentDispositionData =
						"Content-Disposition: form-data; name=\"\(key)\"; filename=\"image.jpg\"\r\n".data(
							using: .utf8),
					let contentTypeData = "Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)
				{
					body.append(boundaryData)
					body.append(contentDispositionData)
					body.append(contentTypeData)
					body.append(data)
				}
			} else {
				// Handle text fields
				if let boundaryData = "\r\n--\(boundary)\r\n".data(using: .utf8),
					let contentDispositionData = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(
						using: .utf8),
					let valueData = "\(value)".data(using: .utf8)
				{
					body.append(boundaryData)
					body.append(contentDispositionData)
					body.append(valueData)
				}
			}
		}

		// Add final boundary
		if let finalBoundaryData = "\r\n--\(boundary)--\r\n".data(using: .utf8) {
			body.append(finalBoundaryData)
		}

		request.httpBody = body

		// Perform the request
		let (data, response): (Data, URLResponse)
		do {
			(data, response) = try await URLSession.shared.data(for: request)
		} catch {
			// Check if this is a cancellation error and handle silently
			if APIError.isCancellation(error) {
				throw APIError.cancelled
			}
			// Re-throw non-cancellation errors
			throw error
		}

		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(url)"
			print(errorMessage ?? "no error message to log")
			throw APIError.failedHTTPRequest(description: "The HTTP request has failed.")
		}

		guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
			errorStatusCode = httpResponse.statusCode

			if errorStatusCode == 401 {
				// Handle token refresh logic here
				let newAccessToken: String = try await handleRefreshToken()
				// Retry the request with the new access token
				let newData = try await retryRequest(request: &request, bearerAccessToken: newAccessToken)
				return newData
			}

			errorMessage = "Invalid status code \(httpResponse.statusCode) for \(url)"
			print(errorMessage ?? "no error message to log")
			throw APIError.invalidStatusCode(statusCode: httpResponse.statusCode)
		}

		return data
	}

	/// Refresh Token
	fileprivate func handleRefreshToken() async throws -> String {
		print("🔄 Attempting to refresh access token...")
		guard let url = URL(string: APIService.baseURL + "auth/refresh-token") else {
			print("❌ ERROR: Failed to create refresh token URL")
			throw APIError.URLError
		}

		guard
			let refreshTokenData = KeychainService.shared.load(key: "refreshToken"),
			let refreshToken = String(data: refreshTokenData, encoding: .utf8)
		else {
			print("❌ ERROR: Missing refresh token in Keychain - cannot refresh")
			print("🔄 Logging out user due to missing refresh token")
			// If refresh token is missing, immediately log out the user to prevent endless retry loops
			await MainActor.run {
				UserAuthViewModel.shared.signOut()
			}
			throw APIError.failedTokenSaving(tokenType: "refreshToken")
		}

		print("🔄 Making refresh token request...")
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")

		let (data, response): (Data, URLResponse)
		do {
			(data, response) = try await URLSession.shared.data(for: request)
		} catch {
			// Check if this is a cancellation error and handle silently
			if APIError.isCancellation(error) {
				throw APIError.cancelled
			}
			// Re-throw non-cancellation errors
			throw error
		}

		guard let httpResponse = response as? HTTPURLResponse else {
			let message = "HTTP request failed for refresh token endpoint"
			print("❌ ERROR: \(message)")
			throw APIError.failedHTTPRequest(description: message)
		}

		print("🔄 Refresh token response status: \(httpResponse.statusCode)")

		if httpResponse.statusCode == 401 {
			// Refresh token is invalid/expired
			print("❌ ERROR: Refresh token invalid (401) - token may be expired")
			print("🔄 Clearing invalid tokens but preserving OAuth credentials for potential re-authentication")

			// Clear the invalid tokens
			let _ = KeychainService.shared.delete(key: "accessToken")
			let _ = KeychainService.shared.delete(key: "refreshToken")

			// Don't call signOut() here - let the calling code handle re-authentication
			// This preserves OAuth credentials for potential re-authentication during onboarding
			throw APIError.invalidStatusCode(statusCode: 401)
		}

		if httpResponse.statusCode == 200 {
			// Successfully refreshed token, extract and save it to Keychain
			if let newAccessToken = httpResponse.allHeaderFields["Authorization"] as? String
				?? httpResponse.allHeaderFields["authorization"] as? String
			{
				let cleanAccessToken = newAccessToken.replacingOccurrences(of: "Bearer ", with: "")
				print("🔐 Received new access token, saving to keychain...")

				if let accessTokenData = cleanAccessToken.data(using: .utf8) {
					if !KeychainService.shared.save(key: "accessToken", data: accessTokenData) {
						print("❌ ERROR: Failed to save refreshed access token to keychain")
						throw APIError.failedTokenSaving(tokenType: "accessToken")
					}
					return "Bearer \(cleanAccessToken)"
				} else {
					print("❌ ERROR: Failed to convert access token to data")
					throw APIError.failedTokenSaving(tokenType: "accessToken")
				}
			} else {
				print("❌ ERROR: No access token found in refresh response headers")
				throw APIError.failedHTTPRequest(description: "No access token in refresh response")
			}
		}

		print("❌ ERROR: Unexpected status code \(httpResponse.statusCode) from refresh endpoint")

		// Log response body for debugging
		if let responseBody = String(data: data, encoding: .utf8) {
			print("🔍 Refresh response body: \(responseBody)")
		}

		throw APIError.failedHTTPRequest(description: "Failed to refresh token - status \(httpResponse.statusCode)")
	}

	fileprivate func retryRequest(request: inout URLRequest, bearerAccessToken: String) async throws -> Data {
		// Retry the request with the new access token
		print("🔄 Retrying request with new access token")
		request.setValue(bearerAccessToken, forHTTPHeaderField: "Authorization")
		let (newData, newResponse) = try await URLSession.shared.data(for: request)
		guard let newHttpResponse = newResponse as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(request.url?.absoluteString ?? "unknown URL")"
			print(errorMessage ?? "no error message to log")
			throw APIError.failedHTTPRequest(description: "The HTTP request has failed.")
		}
		guard (200...299).contains(newHttpResponse.statusCode) else {
			errorMessage =
				"Invalid status code \(newHttpResponse.statusCode) for \(request.url?.absoluteString ?? "unknown URL")"
			print(errorMessage ?? "no error message to log")
			throw APIError.invalidStatusCode(statusCode: newHttpResponse.statusCode)
		}
		return newData
	}

	func validateCache(_ cachedItems: [String: Date]) async throws -> [String: CacheValidationResponse] {
		resetState()

		// Don't send validation request if there are no cached items to validate
		if cachedItems.isEmpty {
			print("No cached items to validate, returning empty response")
			return [:]
		}

		guard let userId = await UserAuthViewModel.shared.spawnUser?.id else {
			throw APIError.invalidData
		}

		// Create the URL for the cache validation endpoint
		guard let url = URL(string: APIService.baseURL + "cache/validate/\(userId)") else {
			throw APIError.URLError
		}

		// Create a wrapper structure that matches the backend DTO
		struct CacheValidationRequest: Codable {
			let timestamps: [String: Date]
		}

		// Wrap the cache items in the expected structure
		let requestBody = CacheValidationRequest(timestamps: cachedItems)

		// Convert to JSON
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		let jsonData = try encoder.encode(requestBody)

		// Create and configure the request
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = "POST"
		urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
		urlRequest.httpBody = jsonData
		setAuthHeader(request: &urlRequest)

		// Send the request
		var (data, response): (Data, URLResponse)
		do {
			(data, response) = try await URLSession.shared.data(for: urlRequest)
		} catch {
			// Check if this is a cancellation error and handle silently
			if APIError.isCancellation(error) {
				// Return empty result for cancelled requests
				return [:]
			}
			// Re-throw non-cancellation errors
			throw error
		}

		// Validate the response
		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(url)"
			print(errorMessage ?? "no error message to log")
			throw APIError.failedHTTPRequest(description: "The HTTP request has failed.")
		}

		if httpResponse.statusCode == 401 {
			let bearerAccessToken: String = try await handleRefreshToken()
			data = try await retryRequest(request: &urlRequest, bearerAccessToken: bearerAccessToken)
		} else if httpResponse.statusCode != 200 {
			errorStatusCode = httpResponse.statusCode
			errorMessage = "invalid status code \(httpResponse.statusCode) for \(url)"
			print(errorMessage ?? "no error message to log")
			throw APIError.invalidStatusCode(statusCode: httpResponse.statusCode)
		}

		// Decode the response
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		let validationResponse = try decoder.decode([String: CacheValidationResponse].self, from: data)

		return validationResponse
	}

	// MARK: - Error Parsing Methods
	private func parseErrorMessage(from data: Data) -> String? {
		// Try to parse as ErrorResponse structure
		if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
			return errorResponse.message
		}

		// Try to parse as generic JSON with message field
		if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			let message = errorJson["message"] as? String
		{
			return message
		}

		// Try to parse as string response
		if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
			return errorString
		}

		return nil
	}

	private func createAPIError(statusCode: Int, data: Data) -> APIError {
		let errorMessage = parseErrorMessage(from: data)

		if let message = errorMessage {
			// Store the error message for the view model to use
			self.errorMessage = message
			print("API Error (\(statusCode)): \(message)")
		} else {
			print("API Error (\(statusCode)): No message available")
		}

		return APIError.invalidStatusCode(statusCode: statusCode)
	}
}

// since the PUT requests don't need any `@RequestBody` in the back-end
struct EmptyRequestBody: Codable, Sendable {}
// for empty responses from requests:
struct EmptyResponse: Codable, Sendable {}
struct EmptyObject: Codable, Sendable {}
