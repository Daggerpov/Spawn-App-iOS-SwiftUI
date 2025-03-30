//
//  MockAPIService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation

class MockAPIService: IAPIService {
    /// This variable dictates whether we'll be using the `MockAPIService()` or `APIService()` throughout the app
    static var isMocking: Bool = false

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
                return [
                    FullFeedEventDTO.mockDinnerEvent,
                    FullFeedEventDTO
                        .mockSelfOwnedEvent,
                    FullFeedEventDTO.mockSelfOwnedEvent2,
                ] as! T
            }
        }

        // fetchTagsForUser():

        if url.absoluteString == APIService.baseURL + "friendTags" {
            return FullFriendTagDTO.mockTags as! T
        }

        /// FriendsTabViewModel.swift:

        if let userIdForUrl = userId {
            // fetchIncomingFriendRequests():

            if url.absoluteString == APIService.baseURL
                + "friend-requests/incoming/\(userIdForUrl)"
            {
                return FetchFriendRequestDTO.mockFriendRequests as! T
            }

            // fetchRecommendedFriends():

            if url.absoluteString == APIService.baseURL
                + "users/recommended-friends/\(userIdForUrl)"
            {
                let firstThreeUsers = Array(
                    RecommendedFriendUserDTO.mockUsers.prefix(3)
                )
                return firstThreeUsers as! T
            }

            // fetchFriends():

            if url.absoluteString == APIService.baseURL
                + "users/friends/\(userIdForUrl)"
            {
                return FullFriendUserDTO.mockUsers as! T
            }
        }

        /// TagsViewModel.swift:
        if let userIdForUrl = userId {
            // fetchTags():

            // "friendTags/owner/\(user.id)"

            if url.absoluteString == APIService.baseURL
                + "friendTags/owner/\(userIdForUrl)"
            {
                return FullFriendTagDTO.mockTags as! T
            }
        }

        /// ChoosingTagViewModel.swift:
        if let userIdForUrl = userId {
            if url.absoluteString == APIService.baseURL
                + "friendTags/addUserToTags/\(userIdForUrl)"
            {
                return FullFriendTagDTO.mockTags as! T
            }
        }

        /// ChoosingTagViewModel.swift:
        if let userIdForUrl = userId {
            if url.absoluteString == APIService.baseURL
                + "friendTags/addUserToTags/\(userIdForUrl)"
            {
                return FullFriendTagDTO.mockTags as! T
            }
        }

        if T.self == UserDTO.self {
            return UserDTO.danielAgapov as! T
        }

        throw APIError.invalidData
    }

    func sendData<T: Encodable, U: Decodable>(
        _ object: T, to url: URL, parameters: [String: String]? = nil
    ) async throws -> U? {
        /// `FriendsTabViewModel.swift`:

        // addFriend():

        if url.absoluteString == APIService.baseURL + "users/friend-request" {
            return FetchFriendRequestDTO(
                id: UUID(),
                senderUser: BaseUserDTO.danielAgapov
            ) as! U?
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
            return FullFriendTagDTO.close as! U?
        }

        throw APIError.invalidData
    }

    func updateData<T: Encodable, U: Decodable>(
        _ object: T, to url: URL, parameters: [String: String]? = nil
    ) async throws -> U {
        /// `TagsViewModel.swift`:

        // upsertTag(upsertAction: .update):
        if url.absoluteString == APIService.baseURL + "friendTags" {
            return FullFriendTagDTO.close as! U
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

    func patchData<T: Encodable, U: Decodable>(
        from url: URL,
        with object: T
    ) async throws -> U {
        // Handle user profile updates
        if url.absoluteString.contains("users/") {
            if U.self == BaseUserDTO.self {
                return BaseUserDTO.danielAgapov as! U
            }
        }

        throw APIError.invalidData
    }

    // Add the mock implementation of updateProfilePicture
    func updateProfilePicture(_ imageData: Data, userId: UUID) async throws
        -> BaseUserDTO
    {
        // Log that we're using the mock implementation
        print("🔍 MOCK: Updating profile picture for user \(userId)")

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        // Create a mock profile picture URL
        let mockProfilePicURL =
            "https://mock-s3.amazonaws.com/profile-pictures/\(UUID().uuidString).jpg"

        // Make a mutable copy of the mock users
        var mockUsers = BaseUserDTO.mockUsers

        // If we have a user with this ID in our mock data, update it
        if let existingUserIndex = mockUsers.firstIndex(where: {
            $0.id == userId
        }) {
            // Update the mock user with the new profile picture URL
            mockUsers[existingUserIndex].profilePicture = mockProfilePicURL
            print(
                "✅ MOCK: Profile picture updated successfully with URL: \(mockProfilePicURL)"
            )
            return mockUsers[existingUserIndex]
        } else {
            // If we don't have a user with this ID, create a simple mock user
            let mockUser = BaseUserDTO(
                id: userId,
                username: "mockuser",
                profilePicture: mockProfilePicURL,
                firstName: "Mock",
                lastName: "User",
                bio: "This is a mock user",
                email: "mock@example.com"
            )
            print(
                "✅ MOCK: Created new mock user with updated profile picture: \(mockProfilePicURL)"
            )
            return mockUser
        }
    }
    
    /// Mock implementation of the multipart form data method
    func sendMultipartFormData(_ formData: [String: Any], to url: URL) async throws -> Data {
        // Log that we're using the mock implementation
        print("🔍 MOCK: Sending multipart form data to \(url)")
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
        
        // Create a mock response
        let mockResponse = ["status": "success", "message": "Form data received successfully"]
        
        // Convert mock response to Data
        if let jsonData = try? JSONSerialization.data(withJSONObject: mockResponse) {
            print("✅ MOCK: Multipart form data sent successfully")
            return jsonData
        } else {
            // If we can't create the mock response, return empty data
            print("⚠️ MOCK: Could not create mock response, returning empty data")
            return Data()
        }
    }
}
