//
//  IAPIService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation

protocol IAPIService {
	var errorMessage: String? { get set }
	/// generic function for fetching (GETting) data from API, given a model of type, T
	func fetchData<T: Decodable>(from url: URL) async throws -> T where T: Decodable
	/// generic function for sending (POSTing)  data to an API, given a model of type, T
	func sendData<T: Encodable>(_ object: T, to url: URL) async throws
	/// generic function for updating (PUTting) data, given a model of type, T
	func updateData<T: Encodable>(_ object: T, to url: URL) async throws
}
