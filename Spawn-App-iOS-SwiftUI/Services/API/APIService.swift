//
//  APIService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation
import UIKit

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
		from url: URL, parameters: [String: String]? = nil
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

		guard httpResponse.statusCode == 200 else {
			errorStatusCode = httpResponse.statusCode
			errorMessage =
				"invalid status code \(httpResponse.statusCode) for \(finalURL)"

			// 404 is fine in the context of our back-end; don't clutter output
			if httpResponse.statusCode != 404 {
				print(errorMessage ?? "no error message to log")
			}

			throw APIError.invalidStatusCode(
				statusCode: httpResponse.statusCode)
		}

		do {
			let decoder = APIService.makeDecoder()

			let decodedData = try decoder.decode(T.self, from: data)
			return decodedData
		} catch {
			errorMessage =
				APIError.failedJSONParsing(url: finalURL).localizedDescription
			print(errorMessage ?? "no error message to log")
			throw APIError.failedJSONParsing(url: finalURL)
		}
	}

	internal func sendData<T: Encodable, U: Decodable>(
		_ object: T,
		to url: URL,
		parameters: [String: String]? = nil
	) async throws -> U {
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

		do {
			let decoder = JSONDecoder()
			decoder.dateDecodingStrategy = .iso8601
			let decodedData = try decoder.decode(U.self, from: data)
			return decodedData
		} catch {
			errorMessage =
				APIError.failedJSONParsing(url: finalURL).localizedDescription
			print(errorMessage ?? "no error message to log")
			throw APIError.failedJSONParsing(url: finalURL)
		}
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

	func sendMultipartData<T: Encodable, U: Decodable>(
		_ object: T,
		imageData: Data?,
		to url: URL,
		parameters: [String: String]? = nil
	) async throws -> U {
		resetState()

		// Create URL with parameters
		var urlComponents = URLComponents(
			url: url, resolvingAgainstBaseURL: false)
		if let parameters = parameters {
			urlComponents?.queryItems = parameters.map {
				URLQueryItem(name: $0.key, value: $0.value)
			}
		}

		guard let finalURL = urlComponents?.url else {
			throw APIError.URLError
		}

		// Create multipart request
		var request = URLRequest(url: finalURL)
		request.httpMethod = "POST"

		let boundary = "Boundary-\(UUID().uuidString)"
		request.setValue(
			"multipart/form-data; boundary=\(boundary)",
			forHTTPHeaderField: "Content-Type")

		var body = Data()

		// Add JSON part
		body.append("--\(boundary)\r\n".data(using: .utf8)!)
		body.append(
			"Content-Disposition: form-data; name=\"userDTO\"\r\n".data(
				using: .utf8)!)
		body.append(
			"Content-Type: application/json\r\n\r\n".data(using: .utf8)!)

		let encoder = APIService.makeEncoder()
		let encodedData = try encoder.encode(object)
		body.append(encodedData)
		body.append("\r\n".data(using: .utf8)!)

		// Add image part if it exists
		if let imageData = imageData {
			body.append("--\(boundary)\r\n".data(using: .utf8)!)
			body.append(
				"Content-Disposition: form-data; name=\"profilePicture\"; filename=\"profile.jpg\"\r\n"
					.data(using: .utf8)!)
			body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
			body.append(imageData)
			body.append("\r\n".data(using: .utf8)!)
		}

		body.append("--\(boundary)--\r\n".data(using: .utf8)!)
		request.httpBody = body

		// Send request
		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIError.failedHTTPRequest(description: "HTTP request failed")
		}

		guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201
		else {
			if let errorString = String(data: data, encoding: .utf8) {
				print("Error response body: \(errorString)")
			}
			throw APIError.invalidStatusCode(
				statusCode: httpResponse.statusCode)
		}

		let decoder = APIService.makeDecoder()
		return try decoder.decode(U.self, from: data)
	}

	func createUser(userDTO: UserCreateDTO, profilePicture: UIImage?, parameters: [String: String]?) async throws -> User {
		resetState()

		// Create URL with parameters
		guard let baseURL = URL(string: APIService.baseURL + "auth/make-user") else {
			throw APIError.URLError
		}

		var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
		if let parameters = parameters {
			urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
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
			"email": userDTO.email
		]

		// Add profile picture data if available
		if let image = profilePicture,
		   let imageData = image.jpegData(compressionQuality: 0.8) {
			userCreationDTO["profilePictureData"] = imageData.base64EncodedString()
		}

		// Create the request
		var request = URLRequest(url: finalURL)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		// Encode the body
		let jsonData = try JSONSerialization.data(withJSONObject: userCreationDTO)
		request.httpBody = jsonData

		// Send the request
		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIError.failedHTTPRequest(description: "HTTP request failed")
		}

		guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
			throw APIError.invalidStatusCode(statusCode: httpResponse.statusCode)
		}

		// Decode the response
		let decoder = APIService.makeDecoder()
		return try decoder.decode(User.self, from: data)
	}

}

// since the PUT requests don't need any `@RequestBody` in the back-end
struct EmptyRequestBody: Codable {}
// for empty responses from requests:
struct EmptyResponse: Codable {}
