//
//  MockAPIService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation

class MockAPIService: IAPIService {
	/// This variable dictates whether we'll be using the `MockAPIService()` or `APIService()` throughout the app
	static var mocking: Bool = false

	func fetchData<T>(from url: URL) async throws -> T where T : Decodable {
		if T.self == User.self {
			return User.danielAgapov as! T
		}
		// TODO: implement other types for mocking later:
		throw APIError.invalidData
	}
}
