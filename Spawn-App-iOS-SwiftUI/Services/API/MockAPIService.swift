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

	var userId: UUID?

	init(userId: UUID? = nil) {
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

		if let userIdForUrl = userId {
			// fetchIncomingFriendRequests():

			if url.absoluteString == APIService.baseURL + "users/\(userIdForUrl)/friend-requests" {
				return FriendRequest.mockFriendRequests as! T
			}

			// fetchRecommendedFriends():

			if url.absoluteString == APIService.baseURL + "users/\(userIdForUrl)/recommended-friends" {
				let firstThreeUsers = Array(User.mockUsers.prefix(3))
				return firstThreeUsers as! T
			}

			// fetchFriends():

			if url.absoluteString == APIService.baseURL + "users/\(userIdForUrl)/friends" {
				return User.mockUsers as! T
			}
		}



		/// TagsViewModel.swift:

		// fetchTags():

		if url.absoluteString == APIService.baseURL + "friendTags" {
			return FriendTag.mockTags as! T
		}

		if T.self == User.self {
			return User.danielAgapov as! T
		}

		throw APIError.invalidData
	}

	func sendData<T>(_ object: T, to url: URL) async throws where T : Encodable {
		/// `FriendsTabViewModel.swift`:

		// addFriend():

		if url.absoluteString == APIService.baseURL + "users/friend-request" {return} // just stop executing

		/// `EventCreationViewModel.swift`:

		// createEvent():

		if url.absoluteString == APIService.baseURL + "events" {return}

		/// TagsViewModel.swift:

		// createTag():

		if url.absoluteString == APIService.baseURL + "friendTags" {return}

		// this means I need to include the url call in this mock `sendData` method:
		throw APIError.invalidData
	}
}
