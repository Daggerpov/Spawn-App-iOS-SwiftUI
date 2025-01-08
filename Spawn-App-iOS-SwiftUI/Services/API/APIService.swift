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

	internal func fetchData<T: Decodable>(from url: URL) async throws -> T where T: Decodable {
		let (data, response) = try await URLSession.shared.data(from: url)

		guard let httpResponse = response as? HTTPURLResponse else {
			errorMessage = "HTTP request failed for \(url)"
			print(errorMessage ?? "no error message to log")

			throw APIError.failedHTTPRequest(description: "The HTTP request has failed.")
		}

		guard httpResponse.statusCode == 200 else {
			errorMessage = "invalid status code for \(url)"
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
}
