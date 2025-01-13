//
//  IAPIService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation

protocol IAPIService {
	var errorMessage: String? { get set }
	/// generic function for fetching data from API, given a model of type, T
	func fetchData<T: Decodable>(from url: URL) async throws -> T where T: Decodable
	/// generic function for sending data to an API, given a model of type, T
	func sendData<T: Encodable>(_ object: T, to url: URL) async throws
}
