//
//  APIService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation

class APIService: IAPIService {
	static var baseURL: String = "https://spawn-app-back-end-production.up.railway.app/api/v1/"

	var errorMessage: String? // TODO: currently not being accessed; maybe use in alert to user

	// Shared JSONDecoder for decoding data from the backend
	/// Note: not currently being used
	private static func makeDecoder() -> JSONDecoder {
		let decoder = JSONDecoder()

		// Custom date decoding strategy
		decoder.dateDecodingStrategy = .custom { decoder -> Date in
			let container = try decoder.singleValueContainer()
			let dateString = try container.decode(String.self)

			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

			if let date = formatter.date(from: dateString) {
				return date
			} else {
				throw DecodingError.dataCorruptedError(in: container,
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
			formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

			let dateString = formatter.string(from: date)
			try container.encode(dateString)
		}
		return encoder
	}

	internal func fetchData<T: Decodable>(from url: URL, parameters: [String: String]? = nil) async throws -> T where T: Decodable {
		// Create a URLComponents object from the URL
		var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)

		// Add query items if parameters are provided
		if let parameters = parameters {
			urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
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
			throw APIError.failedHTTPRequest(description: "The HTTP request has failed.")
		}

		guard httpResponse.statusCode == 200 else {
			errorMessage = "invalid status code \(httpResponse.statusCode) for \(finalURL)"
			print(errorMessage ?? "no error message to log")
			throw APIError.invalidStatusCode(statusCode: httpResponse.statusCode)
		}

		do {
			let decoder = APIService.makeDecoder()
			let decodedData = try decoder.decode(T.self, from: data)
			return decodedData
		} catch {
			errorMessage = APIError.failedJSONParsing(url: finalURL).localizedDescription
			print(errorMessage ?? "no error message to log")
			throw APIError.failedJSONParsing(url: finalURL)
		}
	}

	internal func sendData<T: Encodable, U: Decodable>(
		_ object: T,
		to url: URL,
		parameters: [String: String]? = nil
	) async throws -> U {
		// Create a URLComponents object from the URL
		var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)

		// Add query items if parameters are provided
		if let parameters = parameters {
			urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
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
			throw APIError.failedHTTPRequest(description: "The HTTP request has failed.")
		}

		guard httpResponse.statusCode == 200 else {
			errorMessage = "invalid status code \(httpResponse.statusCode) for \(finalURL)"
			print(errorMessage ?? "no error message to log")
			throw APIError.invalidStatusCode(statusCode: httpResponse.statusCode)
		}

		do {
			let decoder = JSONDecoder()
			decoder.dateDecodingStrategy = .iso8601
			let decodedData = try decoder.decode(U.self, from: data)
			return decodedData
		} catch {
			errorMessage = APIError.failedJSONParsing(url: finalURL).localizedDescription
			print(errorMessage ?? "no error message to log")
			throw APIError.failedJSONParsing(url: finalURL)
		}
	}

	internal func updateData<T: Encodable>(_ object: T, to url: URL) async throws {
		let encoder = APIService.makeEncoder()
		let encodedData = try encoder.encode(object)

		var request = URLRequest(url: url)
		request.httpMethod = "PUT" // only change from `sendData()`
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = encodedData

		let (_, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(url)"
			print(errorMessage ?? "no error message to log")

			throw APIError.failedHTTPRequest(description: "The HTTP request has failed.")
		}

		guard httpResponse.statusCode == 200 else {
			errorMessage = "invalid status code \(httpResponse.statusCode) for \(url)"
			print(errorMessage ?? "no error message to log")

			throw APIError.invalidStatusCode(statusCode: httpResponse.statusCode)
		}
	}
}
