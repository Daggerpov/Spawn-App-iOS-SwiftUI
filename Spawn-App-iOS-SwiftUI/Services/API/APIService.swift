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

	internal func fetchData<T: Decodable>(from url: URL) async throws -> T where T: Decodable {
		let (data, response) = try await URLSession.shared.data(from: url)

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

		do {
			let decodedData = try JSONDecoder().decode(T.self, from: data)
			return decodedData
		} catch {
			errorMessage = APIError.failedJSONParsing.localizedDescription
			print(errorMessage ?? "no error message to log")
			throw APIError.failedJSONParsing
		}
	}

	internal func sendData<T: Encodable>(_ object: T, to url: URL) async throws {
		let encoder = APIService.makeEncoder()
		let encodedData = try encoder.encode(object)

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
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
