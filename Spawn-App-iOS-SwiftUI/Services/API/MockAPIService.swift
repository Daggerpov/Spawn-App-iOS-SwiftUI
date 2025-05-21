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

		// fetchFilteredEvents() - FeedViewModel
		if url.absoluteString.contains("events/friendTag/") {
			// Extract the tag ID from the URL
			return [
				FullFeedEventDTO.mockDinnerEvent,
				FullFeedEventDTO.mockSelfOwnedEvent,
			] as! T
		}

		// ProfileViewModel - fetchEventDetails
		if url.absoluteString.contains(APIService.baseURL + "events/")
			&& !url.absoluteString.contains("events/friendTag/")
			&& !url.absoluteString.contains("events/feedEvents/")
		{
			// Extract event ID from the URL
			let urlComponents = url.absoluteString.components(separatedBy: "/")
			if let eventIdString = urlComponents.last,
				let eventId = UUID(uuidString: eventIdString)
			{
				// Check if we're looking for a specific event by ID
				print("🔍 MOCK: Fetching event details for ID: \(eventId)")

				// For the mock implementation, set event details based on the eventId in CalendarActivityDTO
				// First, add this event to the AppCache
				let eventToCache = FullFeedEventDTO.mockDinnerEvent
				// Give the mock event the requested ID so it matches
				eventToCache.id = eventId

				// Add random variety to the mocked event
				let possibleTitles = [
					"Dinner at The Spot", "Study Session", "Workout at Gym",
					"Coffee Break", "Movie Night", "Game Night", "Beach Day",
				]
				let possibleLocations = [
					"The Spot", "Central Library", "University Gym",
					"Coffee House", "Cinema", "Game Room", "Beach",
				]
				eventToCache.title = possibleTitles.randomElement()
				eventToCache.category =
					EventCategory.allCases.randomElement() ?? .general
				eventToCache.icon = ["🍽️", "📚", "🏋️", "☕", "🎬", "🎮", "🏖️"]
					.randomElement()
				eventToCache.location = Location(
					id: UUID(),
					name: possibleLocations.randomElement() ?? "The Spot",
					latitude: Double.random(in: 49.2...49.3),
					longitude: Double.random(in: -123.3 ... -123.1)
				)

				// Add to cache so it will be found next time
				await MainActor.run {
					AppCache.shared.addOrUpdateEvent(eventToCache)
				}

				return eventToCache as! T
			}

			// Default fallback
			return FullFeedEventDTO.mockDinnerEvent as! T
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

			// SearchViewModel - fetchFilteredResults():
			if url.absoluteString.contains("users/filtered/\(userIdForUrl)") {
				// Create a mock SearchedUserResult
				let result = SearchedUserResult(
					incomingFriendRequests: FetchFriendRequestDTO
						.mockFriendRequests,
					recommendedFriends: Array(
						RecommendedFriendUserDTO.mockUsers.prefix(2)
					),
					friends: Array(FullFriendUserDTO.mockUsers.prefix(3))
				)
				return result as! T
			}

			// ProfileViewModel - fetchUserStats()
			if url.absoluteString == APIService.baseURL
				+ "users/\(userIdForUrl)/stats"
			{
				return UserStatsDTO(
					peopleMet: 24,
					spawnsMade: 15,
					spawnsJoined: 3
				) as! T
			}

			// ProfileViewModel - fetchUserInterests()
			if url.absoluteString == APIService.baseURL
				+ "users/\(userIdForUrl)/interests"
			{
				return ["Music", "Photography", "Hiking", "Reading", "Travel"]
					as! T
			}

			// ProfileViewModel - fetchUserSocialMedia()
			if url.absoluteString == APIService.baseURL
				+ "users/\(userIdForUrl)/social-media"
			{
				return UserSocialMediaDTO(
					id: UUID(),
					userId: userIdForUrl,
					whatsappLink: "https://wa.me/+1234567890",
					instagramLink: "https://www.instagram.com/user_insta"
				) as! T
			}

			// ProfileViewModel - fetchCalendarActivities()
			if url.absoluteString.contains("users/\(userIdForUrl)/calendar") {
				// Generate dynamic calendar activities
				var activities: [CalendarActivityDTO] = []

				// Get current date information
				let currentDate = Date()
				let calendar = Calendar.current
				let currentMonth = calendar.component(.month, from: currentDate)
				let currentYear = calendar.component(.year, from: currentDate)

				// Create a date formatter for consistent dates
				let dateFormatter = DateFormatter.iso8601Full

				// Check if specific month and year were requested
				var targetMonth = currentMonth
				var targetYear = currentYear

				if let parameters = parameters {
					if let monthStr = parameters["month"],
						let month = Int(monthStr)
					{
						targetMonth = month
					}
					if let yearStr = parameters["year"], let year = Int(yearStr)
					{
						targetYear = year
					}
				}

				// Generate events for current month and the next month
				for monthOffset in 0...2 {
					var month = targetMonth + monthOffset
					var year = targetYear

					// Handle year rollover
					if month > 12 {
						month -= 12
						year += 1
					}

					// Create events throughout the month
					for day in [3, 7, 12, 15, 18, 21, 25, 28] {
						// Skip some days randomly to make it more realistic
						if Bool.random() && monthOffset > 0 {
							continue
						}

						// Get potential event categories to use
						let categories: [EventCategory] = [
							.foodAndDrink, .active, .grind, .chill, .general,
						]

						// Add 1-3 events per day
						let numEvents = Int.random(in: 1...3)
						for _ in 0..<numEvents {
							// Select a random category
							let category = categories.randomElement()!

							// Create a date string
							let dateString = String(
								format: "%04d-%02d-%02dT%02d:%02d:00Z",
								year,
								month,
								day,
								Int.random(in: 9...20),  // Random hour
								Int.random(in: 0...59)
							)  // Random minute

							// Generate colors (sometimes override category color)
							var colorHex: String
							if Bool.random() {
								// Use a custom color sometimes
								let colors = [
									"#4CAF50", "#2196F3", "#9C27B0", "#FF9800",
									"#F44336", "#009688", "#673AB7", "#3F51B5",
									"#FFC107",
								]
								colorHex = colors.randomElement()!
							} else {
								// Convert category color to hex
								switch category {
								case .foodAndDrink: colorHex = "#4CAF50"  // Green
								case .active: colorHex = "#2196F3"  // Blue
								case .grind: colorHex = "#9C27B0"  // Purple
								case .chill: colorHex = "#FF9800"  // Orange
								case .general: colorHex = "#757575"  // Gray
								}
							}

							// Sometimes use custom icon instead of category icon
							let useCustomIcon = Bool.random()
							let icon =
								useCustomIcon
								? [
									"🍕", "🏃", "💻", "📚", "🎮", "🎭", "🎨", "🎵", "☕️",
									"🛒", "👨‍👩‍👧‍👦",
								].randomElement() : category.systemIcon()

							// Create event
							if let eventDate = dateFormatter.date(
								from: dateString
							) {
								activities.append(
									CalendarActivityDTO(
										id: UUID(),
										date: eventDate,
										eventCategory: category,
										icon: useCustomIcon ? icon : nil,
										colorHexCode: colorHex,
										eventId: UUID()
									)
								)
							}
						}
					}
				}

				// If no parameters were provided, return all activities
				if parameters == nil || parameters?.isEmpty == true {
					return activities as! T
				}

				// Otherwise, filter for the requested month and year
				let filteredActivities = activities.filter { activity in
					let activityMonth = calendar.component(
						.month,
						from: activity.date
					)
					let activityYear = calendar.component(
						.year,
						from: activity.date
					)
					return activityMonth == targetMonth
						&& activityYear == targetYear
				}

				return filteredActivities as! T
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

			// ChoosingTagViewModel.swift:
			if url.absoluteString == APIService.baseURL
				+ "friendTags/addUserToTags/\(userIdForUrl)"
			{
				return FullFriendTagDTO.mockTags as! T
			}
		}

		/// TaggedPeopleSuggestionsViewModel.swift

		// fetchSuggestedFriends():
		if url.absoluteString.contains("friendTags/friendsNotAddedToTag/") {
			// Return some mock suggested friends
			return BaseUserDTO.mockUsers.prefix(3).map({ $0 }) as! T
		}

		// fetchTagFriends():
		if url.absoluteString.contains("friendTags/")
			&& url.absoluteString.contains("/friends")
		{
			// Return mock added friends
			return BaseUserDTO.mockUsers.prefix(4).map({ $0 }) as! T
		}

		/// AddFriendToTagViewModel.swift:
		if url.absoluteString.contains("friendTags/friendsNotAddedToTag/") {
			// Extract the tag ID from the URL
			return BaseUserDTO.mockUsers as! T
		}

		// EventCardViewModel.swift & EventDescriptionViewModel.swift:
		if url.absoluteString.contains("events/")
			&& url.absoluteString.contains("/participation")
		{
			return FullFeedEventDTO.mockDinnerEvent as! T
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

		/// `EventCreationViewModel.swift`:

		// createEvent():
		if url.absoluteString == APIService.baseURL + "events" {
			// do nothing; whatever
		}

		/// TagsViewModel.swift:

		// upsertTag(upsertAction: .create):
		if url.absoluteString == APIService.baseURL + "friendTags" {
			return FullFriendTagDTO.close as! U?
		}

		// Handle adding/removing friends from tags
		if url.absoluteString.contains("friendTags/") && parameters != nil {
			// Handle the modifyFriendTagFriends endpoint
			if (parameters?["friendTagAction"]) != nil {
				// Return empty success response
				return EmptyObject() as! U?
			}
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

		/// AddFriendToTagViewModel.swift:

		// addSelectedFriendsToTag():
		if url.absoluteString == APIService.baseURL
			+ "friendTags/bulkAddFriendsToTag"
		{
			return EmptyResponse() as! U?
		}

		/// ChoosingTagViewModel.swift:

		// addTagsToFriend():
		if url.absoluteString == APIService.baseURL + "friendTags/addUserToTags"
		{
			return EmptyResponse() as! U?
		}

		throw APIError.invalidData
	}

	func updateData<T: Encodable, U: Decodable>(
		_ object: T,
		to url: URL,
		parameters: [String: String]? = nil
	) async throws -> U {
		/// `TagsViewModel.swift`:

		// upsertTag(upsertAction: .update):
		if url.absoluteString == APIService.baseURL + "friendTags"
			|| url.absoluteString.contains("friendTags/")
		{
			return FullFriendTagDTO.close as! U
		}

		// EventCardViewModel.swift - toggleParticipation():
		if url.absoluteString.contains("events/")
			&& url.absoluteString.contains("/toggleStatus")
		{
			return FullFeedEventDTO.mockDinnerEvent as! U
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

		throw APIError.invalidData
	}

	func deleteData<T: Encodable>(
		from url: URL,
		parameters: [String: String]? = nil,
		object: T? = nil
	) async throws {
		// ProfileViewModel - removeUserInterest
		if url.absoluteString.contains("/interests/") {
			// Successfully "delete" the interest without actually doing anything
			print(
				"🔍 MOCK: Successfully deleted interest from URL: \(url.absoluteString)"
			)
			return
		}

		// Handle tag deletion
		if url.absoluteString.contains("friendTags/") {
			print(
				"🔍 MOCK: Successfully deleted tag from URL: \(url.absoluteString)"
			)
			return
		}

		// UserAuthViewModel - deleteAccount
		if url.absoluteString.contains("users/")
			&& !url.absoluteString.contains("/interests/")
		{
			print(
				"🔍 MOCK: Successfully deleted user account from URL: \(url.absoluteString)"
			)
			return
		}

		// If we get here, just return without doing anything - this is a mock implementation
		print("🔍 MOCK: Called deleteData on URL: \(url.absoluteString)")
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

				case "events":
					// Return mock events data
					let mockEvents = createMockEvents()
					updatedItems = try? JSONEncoder().encode(mockEvents)

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

				case "userTags":
					// Return mock user tags data
					let mockTags = FullFriendTagDTO.mockTags
					updatedItems = try? JSONEncoder().encode(mockTags)

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

	private func createMockEvents() -> [Event] {
		// Return mock events data
		return Event.mockEvents
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
