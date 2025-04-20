//
//  APIService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation
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

class APIService: IAPIService {
	static var baseURL: String =
		"https://spawn-app-back-end-production.up.railway.app/api/v1/"

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

			// Try with fractional seconds first
			let formatterWithFractional = ISO8601DateFormatter()
			formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
			
			if let date = formatterWithFractional.date(from: dateString) {
				return date
			}
			
			// If that fails, try without fractional seconds
			let formatterWithoutFractional = ISO8601DateFormatter()
			formatterWithoutFractional.formatOptions = [.withInternetDateTime]
			
			if let date = formatterWithoutFractional.date(from: dateString) {
				return date
			}
			
			// If both fail, throw an error
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
		setAuthHeaders(request: &request)

		let (data, response) = try await URLSession.shared.data(for: request)

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
			let newAccessToken: String = try handleRefreshToken()
			// Retry the request with the new access token
			data = try await retryRequest(request: &request, bearerAccessToken: newAccessToken)
		} else if httpResponse.statusCode != 200 {
			errorStatusCode = httpResponse.statusCode
			errorMessage =
				"invalid status code \(httpResponse.statusCode) for \(finalURL)"

			// Try to parse error message from response if possible
			if let errorJson = try? JSONSerialization.jsonObject(with: data)
				as? [String: Any]
			{
				print("Error Response: \(errorJson)")
			} else if let errorString = String(data: data, encoding: .utf8) {
				print("Error Response (non-JSON): \(errorString)")
			}

			print(errorMessage ?? "no error message to log")
			throw APIError.invalidStatusCode(
				statusCode: httpResponse.statusCode)
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
				print("Attempting to decode as array and extract the first item")
				
				do {
					// Use JSONSerialization first to check if it's an array
					if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [Any],
					   !jsonObject.isEmpty {
						
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
		setAuthHeaders(request: &request)
		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(finalURL)"
			print(errorMessage ?? "no error message to log")
			throw APIError.failedHTTPRequest(
				description: "The HTTP request has failed.")
		}

		// 200 means success || 201 means created, which is also fine for a POST request
		guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201
		else {
			if httpResponse.statusCode == 401 {
				// Handle token refresh logic here
				let newAccessToken: String = try handleRefreshToken()
				// Retry the request with the new access token
				var newData = try await retryRequest(request: &request, bearerAccessToken: newAccessToken)
				return try APIService.makeDecoder().decode(U.self, from: newData)
			}
			errorMessage =
				"invalid status code \(httpResponse.statusCode) for \(finalURL)"
			print(errorMessage ?? "no error message to log")
			throw APIError.invalidStatusCode(
				statusCode: httpResponse.statusCode)
		}

		if !data.isEmpty {
			do {
				let decoder = JSONDecoder()
				decoder.dateDecodingStrategy = .iso8601
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
		setAuthHeaders(request: &request)
		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			let message = "HTTP request failed for \(finalURL)"
			print(message)
			throw APIError.failedHTTPRequest(description: message)
		}

		guard httpResponse.statusCode == 200 else {
			if httpResponse.statusCode == 401 {
				// Handle token refresh logic here
				let newAccessToken: String = try handleRefreshToken()
				// Retry the request with the new access token
				var newData = try await retryRequest(request: &request, bearerAccessToken: newAccessToken)
				return try APIService.makeDecoder().decode(R.self, from: newData)
			}
			errorStatusCode = httpResponse.statusCode
			let message =
				"Invalid status code \(httpResponse.statusCode) for \(finalURL)"
			print(message)
			throw APIError.invalidStatusCode(
				statusCode: httpResponse.statusCode)
		}

		// Decode the response into the expected type `R`
		let decoder = APIService.makeDecoder()
		return try decoder.decode(R.self, from: data)
	}

	internal func deleteData(from url: URL) async throws {
		resetState()

		var request = URLRequest(url: url)
		request.httpMethod = "DELETE"  // Set the HTTP method to DELETE
		setAuthHeaders(request: &request)  // Set auth headers if needed
		let (_, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(url)"
			print(errorMessage ?? "no error message to log")
			throw APIError.failedHTTPRequest(
				description: "The HTTP request has failed.")
		}

		// Check for a successful status code (204 is commonly used for successful deletions)
		guard httpResponse.statusCode == 204 || httpResponse.statusCode == 200
		else {
			if httpResponse.statusCode == 401 {
				// Handle token refresh logic here
				let newAccessToken: String = try handleRefreshToken()
				// Retry the request with the new access token
				try await retryRequest(request: &request, bearerAccessToken: newAccessToken)
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
			"firstName": userDTO.firstName,
			"lastName": userDTO.lastName,
			"bio": userDTO.bio,
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
			userCreationDTO["profilePicture"] = profilePicUrl // Try this field name as well
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
		let (data, response) = try await URLSession.shared.data(for: request)

		// Check the HTTP response
		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIError.failedHTTPRequest(description: "HTTP request failed")
		}

		// Specifically check for 409 Conflict to handle email already exists case
		if httpResponse.statusCode == 409 {
			print("Conflict detected (409): Email or username likely already in use")
			
			// Try to parse error message from response
			if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			   let message = errorJson["message"] as? String {
				print("Error response: \(message)")
				errorMessage = message
			}
			
			throw APIError.invalidStatusCode(statusCode: 409)
		}

		// Check for success - 200 OK or 201 Created
		guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
			errorStatusCode = httpResponse.statusCode
			errorMessage = "Invalid status code \(httpResponse.statusCode) for user creation"
			
			// Try to parse error message from response
			if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			   let errorMessage = errorJson["message"] as? String {
				print("Error response: \(errorMessage)")
			}
			
			throw APIError.invalidStatusCode(statusCode: httpResponse.statusCode)
		}

		// Parse the response
		let decoder = JSONDecoder()
		return try decoder.decode(BaseUserDTO.self, from: data)
	}

	private func handleAuthTokens(from response: HTTPURLResponse, for url: URL)
		throws
	{
		// Check if this is an auth endpoint
		let authEndpoints = [
			APIService.baseURL + "auth/sign-in",
			APIService.baseURL + "auth/make-user",
		]

		guard
			authEndpoints.contains(where: { url.absoluteString.contains($0) }),
			let accessToken = response.allHeaderFields["Authorization"]
				as? String,
			let refreshToken = response.allHeaderFields["x-refresh-token"]
				as? String
		else {
			return
		}

		// Remove "Bearer " prefix from access token
		let cleanAccessToken = accessToken.replacingOccurrences(
			of: "Bearer ", with: "")

		// Store both tokens in keychain
		if let accessTokenData = cleanAccessToken.data(using: .utf8),
			let refreshTokenData = refreshToken.data(using: .utf8)
		{
			if !KeychainService.shared.save(
				key: "accessToken", data: accessTokenData)
			{
				throw APIError.failedTokenSaving(tokenType: "accessToken")
			}
			if !KeychainService.shared.save(
				key: "refreshToken", data: refreshTokenData)
			{
				throw APIError.failedTokenSaving(tokenType: "refreshToken")
			}
		}
	}

	fileprivate func setAuthHeaders(request: inout URLRequest) {
		guard let url = request.url else {
			print("❌ ERROR: URL is nil")
			return
		}

		// Check if auth headers are needed
		let whitelistedEndpoints = [
			"auth/sign-in",
			"auth/make-user"
		]
		if whitelistedEndpoints.contains(where: { url.absoluteString.contains($0) }) {
			// Don't set auth headers for these endpoints
			return
		}
		// Get the access token from keychain
        guard
            let accessToken = KeychainService.shared.load(key: "accessToken"),
            let refreshToken = KeychainService.shared.load(key: "refreshToken")
		else {
			print("❌ ERROR: Missing access or refresh token in Keychain")
			return
		}

		// Set the auth headers
		request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
		request.addValue("Bearer \(refreshToken)", forHTTPHeaderField: "X-Refresh-Token")
		print("🔑 Auth headers set")

		return
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
		setAuthHeaders(request: &request)
		let (data, response) = try await URLSession.shared.data(for: request)
		
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
				// Handle token refresh logic here
				let newAccessToken: String = try handleRefreshToken()
				// Retry the request with the new access token
				var newData = try await retryRequest(request: &request, bearerAccessToken: newAccessToken)
				return try APIService.makeDecoder().decode(U.self, from: newData)
			}

			errorMessage =
				"invalid status code \(httpResponse.statusCode) for \(url)"
			print("❌ ERROR: Invalid status code \(httpResponse.statusCode) for \(url)")
			
			// Try to parse error message from response
			if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
				print("❌ ERROR DETAILS: \(errorJson)")
			}
			
			throw APIError.invalidStatusCode(
				statusCode: httpResponse.statusCode)
		}

		do {
			let decoder = APIService.makeDecoder()
			let decodedData = try decoder.decode(U.self, from: data)
			print("✅ SUCCESS: Data decoded successfully for \(url.absoluteString)")
			return decodedData
		} catch {
			errorMessage =
				APIError.failedJSONParsing(url: url).localizedDescription
			print("❌ ERROR: JSON parsing failed for \(url): \(error)")
			
			// Log the data that couldn't be parsed
			print("❌ DATA THAT FAILED TO PARSE: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
			
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
		guard let url = URL(string: APIService.baseURL + "users/update-pfp/\(userId)") else {
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
        setAuthHeaders(request: &request)  // Set auth headers if needed
		// Log request headers
		print("🔍 REQUEST HEADERS: \(request.allHTTPHeaderFields ?? [:])")
		
		// Perform the request with detailed logging
		let (data, response) = try await URLSession.shared.data(for: request)
		
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
				let newAccessToken: String = try handleRefreshToken()
				// Retry the request with the new access token
				var newData = try await retryRequest(request: &request, bearerAccessToken: String)
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
			print("✅ SUCCESS: Profile picture updated, new URL: \(updatedUser.profilePicture ?? "nil")")
			return updatedUser
		} catch {
			print("❌ ERROR: Failed to decode user data after profile picture update: \(error)")
			print("❌ DATA THAT FAILED TO PARSE: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
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
		setAuthHeaders(request: &request)  // Set auth headers if needed
		// Create the body
		var body = Data()
		
		for (key, value) in formData {
			if let data = value as? Data {
				// Handle image data
				body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
				body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
				body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
				body.append(data)
			} else {
				// Handle text fields
				body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
				body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
				body.append("\(value)".data(using: .utf8)!)
			}
		}
		
		// Add final boundary
		body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
		
		request.httpBody = body
		
		// Perform the request
		let (data, response) = try await URLSession.shared.data(for: request)
		
		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(url)"
			print(errorMessage ?? "no error message to log")
			throw APIError.failedHTTPRequest(description: "The HTTP request has failed.")
		}
		
		
		guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
			errorStatusCode = httpResponse.statusCode

			if errorStatusCode == 401 {
				// Handle token refresh logic here
				let newAccessToken: String = try handleRefreshToken()
				// Retry the request with the new access token
				var newData = try await retryRequest(request: &request, bearerAccessToken: newAccessToken)
				return newData
			}

			errorMessage = "Invalid status code \(httpResponse.statusCode) for \(url)"
			print(errorMessage ?? "no error message to log")
			throw APIError.invalidStatusCode(statusCode: httpResponse.statusCode)
		}
		
		return data
	}

	fileprivate func setAuthHeaders(request: inout URLRequest) {
		guard let url = request.url else {
			print("❌ ERROR: URL is nil")
			return
		}

		// Check if auth headers are needed
		let whitelistedEndpoints = [
			"auth/sign-in",
			"auth/make-user"
		]
		if whitelistedEndpoints.contains(where: { url.absoluteString.contains($0) }) {
			// Don't set auth headers for these endpoints
			return
		}
		// Get the access token from keychain
		guard
			let accessToken = KeychainService.load("accessToken") as? String, 
			let refreshToken = KeychainService.load("refreshToken") as? String 
			else {
			print("❌ ERROR: Missing access or refresh token in Keychain")
			return
		}

		// Set the auth headers
		request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
		request.addValue("Bearer \(refreshToken)", forHTTPHeaderField: "X-Refresh-Token")
		print("🔑 Auth headers set")
	}

	fileprivate func handleRefreshToken() throws -> String {
		print("Refreshing access token...")
		let url = URL(string: APIService.baseURL + "auth/refresh-token")
		guard let refreshToken = KeychainService.load("refreshToken") as? String else {
			print("❌ ERROR: Missing refresh token in Keychain")
			return
		}

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
		let (data, response) = try await URLSession.shared.data(for: request)
		
		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(url)"
			print(errorMessage ?? "no error message to log")
			throw APIError.failedHTTPRequest(description: "The HTTP request has failed.")
		}
		if httpResponse.statusCode == 200 {
			// Successfully refreshed token, save it to Keychain
			if let newAccessToken = httpResponse.allHeaderFields["Authorization"] as? String {
				let cleanAccessToken = newAccessToken.replacingOccurrences(of: "Bearer ", with: "")

				guard !KeychainService.shared.save(key: "accessToken", data: cleanAccessToken.data(using: .utf8)) else {
					throw APIError.failedTokenSaving(tokenType: "refreshToken")
				}

				return newAccessToken

			}
		} else {
			throw APIError.failedHTTPRequest(description: "Failed to refresh token")
		}
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
			errorMessage = "Invalid status code \(newHttpResponse.statusCode) for \(request.url?.absoluteString ?? "unknown URL")"
			print(errorMessage ?? "no error message to log")
			throw APIError.invalidStatusCode(statusCode: newHttpResponse.statusCode)
		}
		return newData
	}

	func validateCache(_ cachedItems: [String: Date]) async throws -> [String: CacheValidationResponse] {
		resetState()
		
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			throw APIError.invalidData
		}
		
		// Create the URL for the cache validation endpoint
		guard let url = URL(string: APIService.baseURL + "cache/validate/\(userId)") else {
			throw APIError.URLError
		}
		
		// Convert the dictionary of cache items and their timestamps to JSON
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		let jsonData = try encoder.encode(cachedItems)
		
		// Create and configure the request
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = jsonData
		
		// Send the request
		let (data, response) = try await URLSession.shared.data(for: request)
		
		// Validate the response
		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(url)"
			print(errorMessage ?? "no error message to log")
			throw APIError.failedHTTPRequest(description: "The HTTP request has failed.")
		}
		
		guard httpResponse.statusCode == 200 else {
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
}

// since the PUT requests don't need any `@RequestBody` in the back-end
struct EmptyRequestBody: Codable {}
// for empty responses from requests:
struct EmptyResponse: Codable {}
