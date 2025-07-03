//
//  MockAPIService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import Foundation
import SwiftUI // just for UIImage for `createUser()`

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

		// fetchActivitiesForUser():

		if let userIdForUrl = userId {
			// Support for activities endpoint
			if url.absoluteString == APIService.baseURL
				+ "activities/feedActivities/\(userIdForUrl)"
			{
				return [
					FullFeedActivityDTO.mockDinnerActivity,
					FullFeedActivityDTO.mockSelfOwnedActivity,
					FullFeedActivityDTO.mockSelfOwnedActivity2,
				] as! T
			}
		}
        
        if userId != nil {
            if url.absoluteString == APIService.baseURL + "(userIdForUrl)/activity-types" {
                return [
                    ActivityTypeDTO.mockChillActivityType,
                    ActivityTypeDTO.mockFoodActivityType,
                    ActivityTypeDTO.mockActiveActivityType,
                    ActivityTypeDTO.mockStudyActivityType
                ] as! T
            }
        }



		// ProfileViewModel - fetchActivityDetails
		if url.absoluteString.contains(APIService.baseURL + "activities/")
			&& !url.absoluteString.contains("activities/feedActivities/")
		{
			// Extract activity ID from the URL
			let urlComponents = url.absoluteString.components(separatedBy: "/")
			if let activityIdString = urlComponents.last,
				let activityId = UUID(uuidString: activityIdString)
			{
				// Check if we're looking for a specific activity by ID
				print("🔍 MOCK: Fetching activity details for ID: \(activityId)")

				// For the mock implementation, set activity details based on the activityId in CalendarActivityDTO
				// First, add this activity to the AppCache
				let activityToCache = FullFeedActivityDTO.mockDinnerActivity
				// Give the mock activity the requested ID so it matches
				activityToCache.id = activityId

				// Add random variety to the mocked activity
				let possibleTitles = [
					"Dinner at The Spot", "Study Session", "Workout at Gym",
					"Coffee Break", "Movie Night", "Game Night", "Beach Day",
				]
				let possibleLocations = [
					"The Spot", "Central Library", "University Gym",
					"Coffee House", "Cinema", "Game Room", "Beach",
				]
				activityToCache.title = possibleTitles.randomElement()
				activityToCache.category =
					ActivityCategory.allCases.randomElement() ?? .general
				activityToCache.icon = ["🍽️", "📚", "🏋️", "☕", "🎬", "🎮", "🏖️"]
					.randomElement()
				activityToCache.location = Location(
					id: UUID(),
					name: possibleLocations.randomElement() ?? "The Spot",
					latitude: Double.random(in: defaultMapLatitude - 0.05...defaultMapLatitude + 0.05),
					longitude: Double.random(in: defaultMapLongitude - 0.05...defaultMapLongitude + 0.05)
				)

				// Add to cache so it will be found next time
				await MainActor.run {
					AppCache.shared.addOrUpdateActivity(activityToCache)
				}

				return activityToCache as! T
			}

			// Default fallback
			return FullFeedActivityDTO.mockDinnerActivity as! T
		}

		/// FriendRequestViewModel.swift:

		// fetchFriendRequests():
		if url.absoluteString == APIService.baseURL + "friend-requests/\(userId ?? UUID())" {
			return FetchFriendRequestDTO.mockFriendRequests as! T
		}

		// fetchRecommendedFriends():
		if url.absoluteString == APIService.baseURL + "users/recommended/\(userId ?? UUID())" {
			return RecommendedFriendUserDTO.mockUsers as! T
		}

		// fetchFriends():
		if url.absoluteString == APIService.baseURL + "users/friends/\(userId ?? UUID())" {
			return FullFriendUserDTO.mockUsers as! T
		}

		// fetchRecentlySpawnedWith():
		if url.absoluteString == APIService.baseURL + "users/recentlySpawnedWith/\(userId ?? UUID())" {
			return [BaseUserDTO.danielAgapov, Date.now] as! T
		}

		// fetchSearchResults():
		if url.absoluteString == APIService.baseURL + "users/search/\(userId ?? UUID())" {
			return SearchedUserResult(
				incomingFriendRequests: FetchFriendRequestDTO.mockFriendRequests,
				recommendedFriends: RecommendedFriendUserDTO.mockUsers,
				friends: FullFriendUserDTO.mockUsers
			) as! T
		}

		// Handle calendar activities fetch
		if url.absoluteString.contains("users/") && url.absoluteString.contains("/calendar") {
			// Create mock calendar activities based on mock activities
			let mockActivities = createMockCalendarActivities(parameters: parameters)
			
			// If parameters are provided, return activities for that month
			// If no parameters, return all activities
			if let _ = parameters?["month"], let _ = parameters?["year"] {
				return mockActivities as! T
			} else {
				// For fetchAllCalendarActivities, return activities for multiple months
				var allActivities: [CalendarActivityDTO] = []
				
				// Create activities for current month and next 2 months
				let calendar = Calendar.current
				let currentDate = Date()
				
				for monthOffset in 0...2 {
					if let futureDate = calendar.date(byAdding: .month, value: monthOffset, to: currentDate) {
						let month = calendar.component(.month, from: futureDate)
						let year = calendar.component(.year, from: futureDate)
						
						let monthActivities = createMockCalendarActivities(parameters: [
							"month": String(month),
							"year": String(year)
						])
						allActivities.append(contentsOf: monthActivities)
					}
				}
				
				return allActivities as! T
			}
		}

		// ActivityCardViewModel.swift & ActivityDescriptionViewModel.swift:
		if url.absoluteString.contains("activities/")
			&& url.absoluteString.contains("/participation")
		{
			return FullFeedActivityDTO.mockDinnerActivity as! T
		}

		if T.self == UserDTO.self {
			return UserDTO.danielAgapov as! T
		}

		/// UserAuthViewModel.swift:
		if let userIdForUrl = userId {
			if url.absoluteString == APIService.baseURL
				+ "auth/sign-in/\(userIdForUrl)"
			{
				return UserDTO.danielAgapov as! T
			}

			// fetchUserData()
			if url.absoluteString == APIService.baseURL
				+ "users/\(userIdForUrl)"
			{
				return BaseUserDTO.danielAgapov as! T
			}

			// Fetch user interests
			if url.absoluteString.contains("users/") && url.absoluteString.contains("/interests") {
				// Return mock interests
				return ["Hiking", "Photography", "Cooking", "Travel", "Music"] as! T
			}
		}
		


		throw APIError.invalidData
	}

	func sendData<T: Encodable, U: Decodable>(
		_ object: T,
		to url: URL,
		parameters: [String: String]? = nil
	) async throws -> U? {
		/// `FriendsTabViewModel.swift`:

		// addFriend():
		if url.absoluteString == APIService.baseURL + "users/friend-request"
			|| url.absoluteString == APIService.baseURL + "friend-requests"
		{
			return FetchFriendRequestDTO(
				id: UUID(),
				senderUser: BaseUserDTO.danielAgapov
			) as! U?
		}

		/// `ActivityCreationViewModel.swift`:

		// createActivity():
		if url.absoluteString == APIService.baseURL + "activities" {
			// do nothing; whatever
		}
		
		/// ProfileViewModel.swift:

		// addUserInterest():
		if url.absoluteString.contains("users/")
			&& url.absoluteString.contains("/interests")
		{
			return EmptyResponse() as! U?
		}

		/// FeedbackViewModel.swift:

		// submitFeedback():
		if url.absoluteString == APIService.baseURL + "feedback" {
			// Mock successful feedback submission
			if T.self == FeedbackSubmissionDTO.self {
				print("Mocking successful feedback submission")
				return FetchFeedbackSubmissionDTO(
					type: .FEATURE_REQUEST,
					fromUserId: UUID(),
					message: "Test feedback"
				) as! U?
			}
		}

		throw APIError.invalidData
	}

	func createUser(
		userDTO: UserCreateDTO, profilePicture: UIImage?,
		parameters: [String: String]?
	) async throws -> BaseUserDTO {
		return BaseUserDTO.danielAgapov
	}

	func updateData<T: Encodable, U: Decodable>(
		_ object: T,
		to url: URL,
		parameters: [String: String]? = nil
	) async throws -> U {
		/// `TagsViewModel.swift`:

		// ActivityCardViewModel.swift - toggleParticipation():
		if url.absoluteString.contains("activities/")
			&& url.absoluteString.contains("/toggleStatus")
		{
			return FullFeedActivityDTO.mockDinnerActivity as! U
		}

		// FriendRequestViewModel.swift - friendRequestAction():
		if url.absoluteString.contains("friend-requests/")
			&& (parameters?["friendRequestAction"] == "accept"
				|| parameters?["friendRequestAction"] == "reject")
		{
			return EmptyResponse() as! U
		}

		// ProfileViewModel.swift - updateSocialMedia():
		if url.absoluteString.contains("users/")
			&& url.absoluteString.contains("/social-media")
		{
			if let socialMediaDTO = object as? UpdateUserSocialMediaDTO {
				return UserSocialMediaDTO(
					id: UUID(),
					userId: userId ?? UUID(),
					whatsappLink: socialMediaDTO.whatsappNumber != nil
						? "https://wa.me/\(socialMediaDTO.whatsappNumber!)"
						: nil,
					instagramLink: socialMediaDTO.instagramUsername != nil
						? "https://www.instagram.com/\(socialMediaDTO.instagramUsername!)"
						: nil
				) as! U
			}
		}
		
		// Activity type batch update (including pin updates)
		if url.absoluteString.contains("activity-types") && !url.absoluteString.contains("pin") {
			if let batchUpdateDTO = object as? BatchActivityTypeUpdateDTO {
				print("🔍 MOCK: Batch updating activity types with \(batchUpdateDTO.updatedActivityTypes.count) updates and \(batchUpdateDTO.deletedActivityTypeIds.count) deletions")
				
				// Simulate the backend behavior: return ALL user's activity types after the update
				// Start with the mock activity types and apply the changes
				var allActivityTypes = [
					ActivityTypeDTO.mockChillActivityType,
					ActivityTypeDTO.mockFoodActivityType,
					ActivityTypeDTO.mockActiveActivityType,
					ActivityTypeDTO.mockStudyActivityType
				]
				
				// Remove deleted activity types
				allActivityTypes.removeAll { activityType in
					batchUpdateDTO.deletedActivityTypeIds.contains(activityType.id)
				}
				
				// Update or add the updated activity types
				for updatedType in batchUpdateDTO.updatedActivityTypes {
					if let existingIndex = allActivityTypes.firstIndex(where: { $0.id == updatedType.id }) {
						// Update existing activity type
						allActivityTypes[existingIndex] = updatedType
					} else {
						// Add new activity type
						allActivityTypes.append(updatedType)
					}
				}
				
				return allActivityTypes as! U
			}
		}

		throw APIError.invalidData
	}

	func deleteData<T: Encodable>(
		from url: URL,
		parameters: [String: String]? = nil,
		object: T? = nil
	) async throws {
		// Handle delete operations
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
		// Make a mutable copy of the mock users
		var mockUsers = BaseUserDTO.mockUsers

		// Try to find user details for logging
		if let existingUser = mockUsers.first(where: { $0.id == userId }) {
			// Log with user details
			print(
				"🔍 MOCK: Updating profile picture for user \(userId) (username: \(existingUser.username), name: \(existingUser.name ?? ""))"
			)
		} else {
			// Log just the ID if user not found
			print("🔍 MOCK: Updating profile picture for user \(userId)")
		}

		// Simulate network delay
		try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

		// Create a mock profile picture URL
		let mockProfilePicURL =
			"https://mock-s3.amazonaws.com/profile-pictures/\(UUID().uuidString).jpg"

		// If we have a user with this ID in our mock data, update it
		if let existingUserIndex = mockUsers.firstIndex(where: {
			$0.id == userId
		}) {
			// Update the mock user with the new profile picture URL
			mockUsers[existingUserIndex].profilePicture = mockProfilePicURL
			let updatedUser = mockUsers[existingUserIndex]
			print(
				"✅ MOCK: Profile picture updated successfully for user \(userId) (username: \(updatedUser.username), name: \(updatedUser.name ?? "")) with URL: \(mockProfilePicURL)"
			)
			return mockUsers[existingUserIndex]
		} else {
			// If we don't have a user with this ID, create a simple mock user
			let mockUser = BaseUserDTO(
				id: userId,
				username: "mockuser",
				profilePicture: mockProfilePicURL,
				name: "Mock User",
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
	func sendMultipartFormData(_ formData: [String: Any], to url: URL)
		async throws -> Data
	{
		// Log that we're using the mock implementation
		print("🔍 MOCK: Sending multipart form data to \(url)")

		// Simulate network delay
		try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

		// Create a mock response
		let mockResponse = [
			"status": "success", "message": "Form data received successfully",
		]

		// Convert mock response to Data
		if let jsonData = try? JSONSerialization.data(
			withJSONObject: mockResponse
		) {
			print("✅ MOCK: Multipart form data sent successfully")
			return jsonData
		} else {
			// If we can't create the mock response, return empty data
			print(
				"⚠️ MOCK: Could not create mock response, returning empty data"
			)
			return Data()
		}
	}

	func validateCache(_ cachedItems: [String: Date]) async throws -> [String:
		CacheValidationResponse]
	{
		// Don't send validation request if there are no cached items to validate
		if cachedItems.isEmpty {
			print("MOCK: No cached items to validate, returning empty response")
			return [:]
		}
		
		// In the mock implementation, we'll pretend everything is fresh except for items
		// that are older than 30 minutes
		var result: [String: CacheValidationResponse] = [:]

		for (key, timestamp) in cachedItems {
			let timeElapsed = Date().timeIntervalSince(timestamp)
			let needsInvalidation = timeElapsed > 1800  // 30 minutes

			// For demo purposes, we'll simulate invalidation based on time elapsed
			if needsInvalidation {
				// Create mock data based on the cache key
				var updatedItems: Data?

				switch key {
				case "friends":
					// Return mock friends data
					let mockFriends = createMockFriends()
					updatedItems = try? JSONEncoder().encode(mockFriends)

				case "activities":
					// Return mock activities data
					let mockActivities = createMockActivities()
					updatedItems = try? JSONEncoder().encode(mockActivities)

				case "profilePicture":
					// Return mock profile picture data
					if let userId = userId
						?? UserAuthViewModel.shared.spawnUser?.id
					{
						let mockProfile = BaseUserDTO(
							id: userId,
							username: "mockuser",
							profilePicture:
								"https://mock-s3.amazonaws.com/profile-pictures/\(UUID().uuidString).jpg",
							name: "Mock User",
							bio: "This is a mock user",
							email: "mock@example.com"
						)
						updatedItems = try? JSONEncoder().encode(mockProfile)
					}

				case "recommendedFriends":
					// Return mock recommended friends data
					let mockRecommendedFriends = Array(
						RecommendedFriendUserDTO.mockUsers.prefix(3)
					)
					updatedItems = try? JSONEncoder().encode(
						mockRecommendedFriends
					)

				case "friendRequests":
					// Return mock friend requests data
					let mockFriendRequests = FetchFriendRequestDTO
						.mockFriendRequests
					updatedItems = try? JSONEncoder().encode(mockFriendRequests)

				case "otherProfiles":
					// For other profiles, we don't include data to force a separate fetch
					updatedItems = nil

				case "tagFriends":
					// For tag friends, we don't include data to force a separate fetch
					updatedItems = nil

				default:
					updatedItems = nil
				}

				result[key] = CacheValidationResponse(
					invalidate: true,
					updatedItems: updatedItems
				)
			} else {
				result[key] = CacheValidationResponse(invalidate: false)
			}
		}

		return result
	}

	// Helper methods to create mock data
	private func createMockFriends() -> [FullFriendUserDTO] {
		// Return mock friends data
		return UserDTO.mockUsers.compactMap { userDTO in
			return FullFriendUserDTO(
				id: userDTO.id,
				username: userDTO.username,
				profilePicture: userDTO.profilePicture,
				name: userDTO.name,
				bio: userDTO.bio,
				email: userDTO.email
			)
		}
	}

	private func createMockActivities() -> [FullFeedActivityDTO] {
		// Return mock activities data
		return [
			FullFeedActivityDTO.mockDinnerActivity,
			FullFeedActivityDTO.mockSelfOwnedActivity,
			FullFeedActivityDTO.mockSelfOwnedActivity2
		]
	}

	private func createMockCalendarActivities(parameters: [String: String]?) -> [CalendarActivityDTO] {
		// Get the current month and year from parameters, or use current date
		let calendar = Calendar.current
		let currentDate = Date()
		let month = parameters?["month"].flatMap(Int.init) ?? calendar.component(.month, from: currentDate)
		let year = parameters?["year"].flatMap(Int.init) ?? calendar.component(.year, from: currentDate)

		// Create a date components for the specified month
		var dateComponents = DateComponents()
		dateComponents.year = year
		dateComponents.month = month

		// Create mock activities based on mock activities
		var activities: [CalendarActivityDTO] = []

		// Use the mock activities to create calendar activities
		let mockActivities = [
			FullFeedActivityDTO.mockDinnerActivity,
			FullFeedActivityDTO.mockSelfOwnedActivity,
			FullFeedActivityDTO.mockSelfOwnedActivity2
		]

		// Create activities spread throughout the month
		for (index, activity) in mockActivities.enumerated() {
			// Create multiple activities per activity
			for dayOffset in [3, 8, 15, 22] {
				dateComponents.day = dayOffset + index
				if let date = calendar.date(from: dateComponents) {
					let calendarActivity = CalendarActivityDTO(
						id: UUID(),
						date: date,
						activityCategory: activity.category,
						icon: activity.icon,
						colorHexCode: activity.category.color().hex,
						activityId: activity.id
					)
					activities.append(calendarActivity)
				}
			}
		}

		return activities
	}
}

// Add DateFormatter extension for ISO8601
extension DateFormatter {
	static let iso8601Full: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
		formatter.calendar = Calendar(identifier: .iso8601)
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		formatter.locale = Locale(identifier: "en_US_POSIX")
		return formatter
	}()
}
