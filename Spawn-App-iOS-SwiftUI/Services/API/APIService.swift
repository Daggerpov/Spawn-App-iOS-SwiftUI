//
//  APIService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation
import UIKit

class APIService: IAPIService {
	// randomly partition server calls between prod & staging to test both
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

			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [
				.withInternetDateTime, .withFractionalSeconds,
			]

			if let date = formatter.date(from: dateString) {
				return date
			} else {
				throw DecodingError.dataCorruptedError(
					in: container,
					debugDescription: "Invalid date format: \(dateString)")
			}
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
			formatter.formatOptions = [
				.withInternetDateTime, .withFractionalSeconds,
			]

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

		let (data, response) = try await URLSession.shared.data(from: finalURL)

		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(finalURL)"
			print(errorMessage ?? "no error message to log")
			throw APIError.failedHTTPRequest(
				description: "The HTTP request has failed.")
		}

		// Handle auth tokens if present
		try handleAuthTokens(from: httpResponse, for: finalURL)

		// TODO: once solved in back-end, remove this
		guard httpResponse.statusCode == 200 || httpResponse.statusCode == 404 else {
			errorStatusCode = httpResponse.statusCode
			errorMessage =
				"invalid status code \(httpResponse.statusCode) for \(finalURL)"

			// Try to parse error message from response if possible
			if let errorJson = try? JSONSerialization.jsonObject(with: data)
				as? [String: Any]
			{
				print("Error Response: \(errorJson)")
			}

			print(errorMessage ?? "no error message to log")
			throw APIError.invalidStatusCode(
				statusCode: httpResponse.statusCode)
		}

		do {
			let decoder = APIService.makeDecoder()

			// Try parsing with more detailed error handling
			do {
				let decodedData = try decoder.decode(T.self, from: data)
				return decodedData
			} catch DecodingError.keyNotFound(let key, let context) {
				print(
					"Missing key: \(key.stringValue) - \(context.debugDescription)"
				)
				throw APIError.failedJSONParsing(url: finalURL)
			} catch DecodingError.typeMismatch(let type, let context) {
				print(
					"Type mismatch: expected \(type) - \(context.debugDescription)"
				)
				throw APIError.failedJSONParsing(url: finalURL)
			} catch DecodingError.valueNotFound(let type, let context) {
				print(
					"Value not found: expected \(type) - \(context.debugDescription)"
				)
				throw APIError.failedJSONParsing(url: finalURL)
			} catch DecodingError.dataCorrupted(let context) {
				print("Data corrupted: \(context.debugDescription)")
				throw APIError.failedJSONParsing(url: finalURL)
			}
		} catch {
			errorMessage =
				APIError.failedJSONParsing(url: finalURL).localizedDescription
			print("JSON Parsing Error: \(error)")
			// Print received data for debugging
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

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			let message = "HTTP request failed for \(finalURL)"
			print(message)
			throw APIError.failedHTTPRequest(description: message)
		}

		guard httpResponse.statusCode == 200 else {
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
	) async throws -> UserDTO {
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

		// Convert UserCreateDTO to UserCreationDTO format
		var userCreationDTO: [String: Any] = [
			"username": userDTO.username,
			"firstName": userDTO.firstName,
			"lastName": userDTO.lastName,
			"bio": userDTO.bio,
			"email": userDTO.email,
		]

		// Add profile picture data if available
		if let image = profilePicture,
			let imageData = image.jpegData(compressionQuality: 0.8)
		{
			userCreationDTO["profilePictureData"] =
				imageData.base64EncodedString()
		}

		// Create the request
		var request = URLRequest(url: finalURL)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		// Encode the body
		let jsonData = try JSONSerialization.data(
			withJSONObject: userCreationDTO)
		request.httpBody = jsonData

		// Send the request
		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIError.failedHTTPRequest(description: "HTTP request failed")
		}

		guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201
		else {
			throw APIError.invalidStatusCode(
				statusCode: httpResponse.statusCode)
		}

		// Decode the response
		let decoder = APIService.makeDecoder()
		return try decoder.decode(UserDTO.self, from: data)
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
}

// since the PUT requests don't need any `@RequestBody` in the back-end
struct EmptyRequestBody: Codable {}
// for empty responses from requests:
struct EmptyResponse: Codable {}
