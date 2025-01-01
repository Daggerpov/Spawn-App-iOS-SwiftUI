//
//  MockAPIService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation

class MockAPIService: IAPIService {
	func fetchData<T>(from url: URL) async throws -> T where T : Decodable {
		if T.self == User.self {
			return User.danielAgapov as! T
		}
		// TODO: implement other types for mocking later:
		throw APIError.invalidData
	}
}
