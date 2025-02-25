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
	var errorStatusCode: Int? = nil

	var userId: UUID?

	init(userId: UUID? = nil) {
		self.userId = userId
	}

	func fetchData<T>(from url: URL, parameters: [String: String]? = nil)
		async throws -> T where T: Decodable
	{
		/// FeedViewModel.swift:

		// fetchEventsForUser():

		if let userIdForUrl = userId {
			if url.absoluteString == APIService.baseURL
				+ "events/feedEvents/\(userIdForUrl)"
			{
				return Event.mockEvents as! T
			}
		}

		// fetchTagsForUser():

		if url.absoluteString == APIService.baseURL + "friendTags" {
			return FriendTag.mockTags as! T
		}

		/// FriendsTabViewModel.swift:

		if let userIdForUrl = userId {
			// fetchIncomingFriendRequests():

			if url.absoluteString == APIService.baseURL
				+ "friend-requests/incoming/\(userIdForUrl)"
			{
				return FriendRequest.mockFriendRequests as! T
			}

			// fetchRecommendedFriends():

			if url.absoluteString == APIService.baseURL
				+ "users/\(userIdForUrl)/recommended-friends"
			{
				let firstThreeUsers = Array(User.mockUsers.prefix(3))
				return firstThreeUsers as! T
			}

			// fetchFriends():

			if url.absoluteString == APIService.baseURL
				+ "users/\(userIdForUrl)/friends"
			{
				return FriendUserDTO.mockUsers as! T
			}
		}

		/// TagsViewModel.swift:
		if let userIdForUrl = userId {
			// fetchTags():

			// "friendTags/owner/\(user.id)"

			if url.absoluteString == APIService.baseURL
				+ "friendTags/owner/\(userIdForUrl)"
			{
				return FriendTag.mockTags as! T
			}
		}
        
        /// ChoosingTagViewModel.swift:
        if let userIdForUrl = userId {
            if url.absoluteString == APIService.baseURL
                + "friendTags/addUserToTags/\(userIdForUrl)"
            {
                return FriendTag.mockTags as! T
            }
        }

		if T.self == User.self {
			return User.danielAgapov as! T
		}

		throw APIError.invalidData
	}

	func sendData<T: Encodable, U: Decodable>(
		_ object: T, to url: URL, parameters: [String: String]? = nil
	) async throws -> U {
		/// `FriendsTabViewModel.swift`:

		// addFriend():

		if url.absoluteString == APIService.baseURL + "users/friend-request" {
			return FriendRequest(
				id: UUID(),
				senderUser: User.danielAgapov,
				receiverUser: User.danielLee
			) as! U
		}

		/// `EventCreationViewModel.swift`:

		// createEvent():

		if url.absoluteString == APIService.baseURL + "events" {
			//			return Event.mockEvents as! U
			// do nothing; whatever
		}

		/// TagsViewModel.swift:

		// upsertTag(upsertAction: .create):

		if url.absoluteString == APIService.baseURL + "friendTags" {
			return FriendTag.close as! U
		}

		// this means I need to include the url call in this mock `sendData` method:
		throw APIError.invalidData
	}

	func updateData<T: Encodable, U: Decodable>(
		_ object: T, to url: URL, parameters: [String: String]? = nil
	) async throws -> U {
		/// `TagsViewModel.swift`:

		// upsertTag(upsertAction: .update):
		if url.absoluteString == APIService.baseURL + "friendTags" {
			return FriendTag.close as! U
		}

		// Example: Updating an event's participation status
		if url.absoluteString.contains("events/")
			&& url.absoluteString.contains("/toggleStatus")
		{
			// do nothing; whatever
		}

		throw APIError.invalidData
	}

	func deleteData(from url: URL) async throws {
		// do nothing
	}
}
