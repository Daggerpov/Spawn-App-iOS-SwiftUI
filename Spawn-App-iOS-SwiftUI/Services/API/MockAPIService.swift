//
//  MockAPIService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation

class MockAPIService: IAPIService {
	/// This variable dictates whether we'll be using the `MockAPIService()` or `APIService()` throughout the app
	static var isMocking: Bool = true

	var errorMessage: String? = nil

	var userId: UUID

	init(userId: UUID) {
		self.userId = userId
	}

	func fetchData<T>(from url: URL) async throws -> T where T : Decodable {
		/// FeedViewModel.swift:

		// fetchEventsForUser():

		if url.absoluteString == APIService.baseURL + "events" {
			return Event.mockEvents as! T
		}

		// fetchTagsForUser():

		if url.absoluteString == APIService.baseURL + "friendTags" {
			return FriendTag.mockTags as! T
		}

		/// FriendsTabViewModel.swift:

		// fetchIncomingFriendRequests():

		if url.absoluteString == APIService.baseURL + "users/\(userId)/friend-requests" {
			return FriendRequest.mockFriendRequests as! T
		}

		// fetchRecommendedFriends():

		if url.absoluteString == APIService.baseURL + "users/\(userId)/recommended-friends" {
			return User.mockUsers as! T
		}

		// fetchFriends():

		if url.absoluteString == APIService.baseURL + "users/\(userId)/friends" {
			return User.mockUsers as! T
		}

		if T.self == User.self {
			return User.danielAgapov as! T
		}
		// TODO: implement other types for mocking later:
		throw APIError.invalidData
	}

	func sendData<T>(_ object: T, to url: URL) async throws where T : Encodable {
		throw APIError.invalidData
	}
}
