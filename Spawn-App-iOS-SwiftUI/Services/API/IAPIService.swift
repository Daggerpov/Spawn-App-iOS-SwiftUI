//
//  IAPIService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation
import SwiftUI // just for UIImage for `createUser()`

protocol IAPIService {
	var errorMessage: String? { get set }
	var errorStatusCode: Int? { get set }
	/// generic function for fetching (GETting) data from API, given a model of type, T, and possibly other request parameters
	func fetchData<T: Decodable>(from url: URL, parameters: [String: String]?)
		async throws -> T where T: Decodable
	/// generic function for sending (POSTing)  data to an API, given a model of type, T
    func sendData<T: Encodable, U: Decodable>(
		_ object: T, to url: URL, parameters: [String: String]?
	) async throws -> U? where U: Decodable
    func sendData<T: Encodable>(
        _ object: T, to url: URL, parameters: [String: String]?
    ) async throws -> T? where T: Decodable
	/// generic function for updating (PUTting) data, given a model of type, T, and returning the updated object
	func updateData<T: Encodable, U: Decodable>(
		_ object: T, to url: URL, parameters: [String: String]?
	) async throws -> U
	/// generic function for patching (PATCHing) data, given a model of type T, and returning the updated object
	func patchData<T: Encodable, U: Decodable>(
		from url: URL,
		with object: T
	) async throws -> U
    func deleteData<T: Encodable>(from url: URL, parameters: [String: String]?, object: T?) async throws
	func updateProfilePicture(_ imageData: Data, userId: UUID) async throws -> BaseUserDTO
	func sendMultipartFormData(_ formData: [String: Any], to url: URL) async throws -> Data
	func validateCache(_ cachedItems: [String: Date]) async throws -> [String: CacheValidationResponse]
	func clearCalendarCaches() async throws
	func createUser(
		userDTO: UserCreateDTO, profilePicture: UIImage?,
		parameters: [String: String]?
	) async throws -> BaseUserDTO
}
