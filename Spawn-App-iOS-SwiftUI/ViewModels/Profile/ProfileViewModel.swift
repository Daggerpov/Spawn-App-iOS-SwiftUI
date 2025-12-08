import Observation
import SwiftUI

@Observable
@MainActor
final class ProfileViewModel {
	var userStats: UserStatsDTO?
	var userInterests: [String] = []
	var originalUserInterests: [String] = []  // Backup for cancel functionality
	var userSocialMedia: UserSocialMediaDTO?
	var userProfileInfo: UserProfileInfoDTO?
	var isLoadingStats: Bool = false
	var isLoadingInterests: Bool = false
	var isLoadingSocialMedia: Bool = false
	var isLoadingProfileInfo: Bool = false
	var showDrawer: Bool = false
	var errorMessage: String?
	var calendarActivities: [[CalendarActivityDTO?]] = Array(
		repeating: Array(repeating: nil, count: 7),
		count: 5
	)
	var isLoadingCalendar: Bool = false
	var allCalendarActivities: [CalendarActivityDTO] = []
	var selectedActivity: FullFeedActivityDTO?
	var isLoadingActivity: Bool = false

	// New property to store all activities organized by day position in the grid
	var calendarActivitiesByDay: [[[CalendarActivityDTO]]] = Array(
		repeating: Array(repeating: [CalendarActivityDTO](), count: 7),
		count: 5
	)

	// New properties for friendship status
	var friendshipStatus: FriendshipStatus = .unknown
	var isLoadingFriendshipStatus: Bool = false
	var pendingFriendRequestId: UUID?
	var userActivities: [FullFeedActivityDTO] = []
	var profileActivities: [ProfileActivityDTO] = []
	var isLoadingUserActivities: Bool = false

	private let dataService: DataService

	init(
		userId: UUID? = nil,
		dataService: DataService? = nil
	) {
		self.dataService = dataService ?? DataService.shared
	}

	func fetchUserStats(userId: UUID) async {
		// Check if user is still authenticated before making API call
		guard UserAuthViewModel.shared.spawnUser != nil, UserAuthViewModel.shared.isLoggedIn else {
			print("Cannot fetch user stats: User is not logged in")
			self.isLoadingStats = false
			return
		}

		let result: DataResult<UserStatsDTO> = await dataService.read(
			.profileStats(userId: userId),
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let stats, _):
			self.userStats = stats
			self.isLoadingStats = false

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			self.isLoadingStats = false
		}
	}

	func fetchUserInterests(userId: UUID) async {
		let result: DataResult<[String]> = await dataService.read(
			.profileInterests(userId: userId),
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let interests, _):
			self.userInterests = interests
			self.isLoadingInterests = false

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			self.isLoadingInterests = false
		}
	}

	func addUserInterest(userId: UUID, interest: String) async -> Bool {
		// Update local state immediately for better UX
		self.userInterests.append(interest)

		// Use DataService for the POST operation
		let operation = WriteOperation<String>.post(
			endpoint: "users/\(userId)/interests",
			body: interest,
			cacheInvalidationKeys: ["profileInterests_\(userId)"]
		)

		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(operation)

		switch result {
		case .success:
			// Refresh interests from cache after successful update
			let refreshResult: DataResult<[String]> = await dataService.read(
				.profileInterests(userId: userId),
				cachePolicy: .apiOnly
			)

			if case .success(let interests, _) = refreshResult {
				self.userInterests = interests
			}
			return true

		case .failure(let error):
			// Revert local state if API call fails
			self.userInterests.removeAll { $0 == interest }
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			return false
		}
	}

	func fetchUserSocialMedia(userId: UUID) async {
		let result: DataResult<UserSocialMediaDTO> = await dataService.read(
			.profileSocialMedia(userId: userId),
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let socialMedia, _):
			self.userSocialMedia = socialMedia
			self.isLoadingSocialMedia = false

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			self.isLoadingSocialMedia = false
		}
	}

	func updateSocialMedia(
		userId: UUID,
		whatsappLink: String?,
		instagramLink: String?
	) async {
		let updateDTO = UpdateUserSocialMediaDTO(
			whatsappNumber: whatsappLink,
			instagramUsername: instagramLink
		)

		// Use WriteOperationType configuration
		let operationType = WriteOperationType.updateSocialMedia(userId: userId, socialMedia: updateDTO)
		let result: DataResult<UserSocialMediaDTO> = await dataService.write(operationType, body: updateDTO)

		switch result {
		case .success(let updatedSocialMedia, _):
			self.userSocialMedia = updatedSocialMedia

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
		}
	}

	func fetchUserProfileInfo(userId: UUID) async {
		// Check if user is still authenticated before making API call
		guard UserAuthViewModel.shared.spawnUser != nil, UserAuthViewModel.shared.isLoggedIn else {
			print("Cannot fetch profile info: User is not logged in")
			self.isLoadingProfileInfo = false
			return
		}

		self.isLoadingProfileInfo = true

		// Use centralized DataType configuration
		let result: DataResult<UserProfileInfoDTO> = await dataService.read(
			.profileInfo(userId: userId, requestingUserId: nil))

		switch result {
		case .success(let profileInfo, _):
			self.userProfileInfo = profileInfo
			self.isLoadingProfileInfo = false

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			self.isLoadingProfileInfo = false
		}
	}

	/// Loads critical profile data that's required for the view to render meaningfully
	/// This should be called on MainActor to block view appearance until data is ready
	func loadCriticalProfileData(userId: UUID) async {
		// Fetch critical data in parallel for faster loading
		// These are essential for the profile to be interactive
		async let stats: () = fetchUserStats(userId: userId)
		async let profileInfo: () = fetchUserProfileInfo(userId: userId)
		async let interests: () = fetchUserInterests(userId: userId)

		// Wait for all critical data to be ready
		let _ = await (stats, profileInfo, interests)
	}

	/// Loads enhancement data that can be progressively loaded
	/// This can be called in a background task without blocking the view
	func loadEnhancementData(userId: UUID) async {
		// Social media is less critical - can load after view appears
		await fetchUserSocialMedia(userId: userId)
	}

	func loadAllProfileData(userId: UUID) async {
		// Use async let to fetch all profile data in parallel for faster loading
		async let stats: () = fetchUserStats(userId: userId)
		async let interests: () = fetchUserInterests(userId: userId)
		async let socialMedia: () = fetchUserSocialMedia(userId: userId)
		async let profileInfo: () = fetchUserProfileInfo(userId: userId)

		// Wait for all fetches to complete
		let _ = await (stats, interests, socialMedia, profileInfo)
	}

	func fetchCalendarActivities(month: Int, year: Int) async {
		self.isLoadingCalendar = true

		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			self.isLoadingCalendar = false
			self.errorMessage = "User ID not available"
			return
		}

		// Use centralized DataType configuration
		let result: DataResult<[CalendarActivityDTO]> = await dataService.read(
			.calendar(userId: userId, month: month, year: year, requestingUserId: nil)
		)

		switch result {
		case .success(let activities, _):
			let grid = convertToCalendarGrid(
				activities: activities,
				month: month,
				year: year
			)

			self.calendarActivities = grid
			self.isLoadingCalendar = false

			// Pre-assign colors for calendar activities
			let activityIds = activities.compactMap { $0.activityId }
			ActivityColorService.shared.assignColorsForActivities(activityIds)

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			self.calendarActivities = Array(
				repeating: Array(repeating: nil, count: 7),
				count: 5
			)
			self.isLoadingCalendar = false
		}
	}

	func fetchAllCalendarActivities() async {
		self.isLoadingCalendar = true

		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("❌ Calendar: No user ID available")
			self.isLoadingCalendar = false
			self.errorMessage = "User ID not available"
			return
		}

		print("📡 Calendar: Fetching activities for user \(userId)")

		// Check authentication status
		let hasAccessToken = KeychainService.shared.load(key: "accessToken") != nil
		let hasRefreshToken = KeychainService.shared.load(key: "refreshToken") != nil
		let isLoggedIn = UserAuthViewModel.shared.isLoggedIn
		print(
			"🔐 Calendar: Authentication status - Access token: \(hasAccessToken ? "✅" : "❌"), Refresh token: \(hasRefreshToken ? "✅" : "❌"), Logged in: \(isLoggedIn ? "✅" : "❌")"
		)

		if !hasAccessToken && !hasRefreshToken {
			print("❌ Calendar: No authentication tokens found - user may need to log in")
			self.errorMessage = "Authentication required - please log in again"
			self.allCalendarActivities = []
			self.isLoadingCalendar = false
			return
		}

		// Use centralized DataType configuration
		let result: DataResult<[CalendarActivityDTO]> = await dataService.read(
			.calendarAll(userId: userId, requestingUserId: nil)
		)

		switch result {
		case .success(let activities, _):
			if !activities.isEmpty {
				print("📅 Calendar: Sample activity dates:")
				for activity in activities.prefix(3) {
					print("   - \(activity.date): \(activity.title ?? "No title")")
				}
			}

			self.allCalendarActivities = activities
			self.isLoadingCalendar = false

			// Pre-assign colors for calendar activities
			let activityIds = activities.compactMap { $0.activityId }
			ActivityColorService.shared.assignColorsForActivities(activityIds)

		case .failure(let error):
			print("❌ Calendar: Error fetching activities")
			print("❌ Calendar: Error details: \(error)")

			let errorMsg = ErrorFormattingService.shared.formatError(error)
			self.errorMessage = errorMsg
			self.allCalendarActivities = []
			self.isLoadingCalendar = false
		}
	}

	// Method to fetch all calendar activities for a friend
	func fetchAllCalendarActivities(friendUserId: UUID) async {
		self.isLoadingCalendar = true

		guard let requestingUserId = UserAuthViewModel.shared.spawnUser?.id else {
			print("❌ ProfileViewModel: No requesting user ID available for calendar activities")
			self.isLoadingCalendar = false
			self.errorMessage = "User ID not available"
			return
		}

		print("🔄 ProfileViewModel: Fetching all calendar activities for friend: \(friendUserId)")

		// Use centralized DataType configuration
		let result: DataResult<[CalendarActivityDTO]> = await dataService.read(
			.calendarAll(userId: friendUserId, requestingUserId: requestingUserId)
		)

		switch result {
		case .success(let activities, _):
			self.allCalendarActivities = activities
			self.isLoadingCalendar = false

			// Pre-assign colors for calendar activities
			let activityIds = activities.compactMap { $0.activityId }
			ActivityColorService.shared.assignColorsForActivities(activityIds)

		case .failure(let error):
			print(
				"❌ ProfileViewModel: Error fetching friend's all calendar activities: \(ErrorFormattingService.shared.formatError(error))"
			)
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			self.allCalendarActivities = []
			self.isLoadingCalendar = false
		}
	}

	// Method to fetch friend's calendar activities
	func fetchFriendCalendarActivities(friendUserId: UUID, month: Int, year: Int) async {
		self.isLoadingCalendar = true

		guard let requestingUserId = UserAuthViewModel.shared.spawnUser?.id else {
			print("❌ ProfileViewModel: No requesting user ID available for calendar activities")
			self.isLoadingCalendar = false
			self.errorMessage = "User ID not available"
			return
		}

		print("🔄 ProfileViewModel: Fetching calendar activities for friend: \(friendUserId)")
		print("📅 Month: \(month), Year: \(year)")

		// Use centralized DataType configuration
		let result: DataResult<[CalendarActivityDTO]> = await dataService.read(
			.calendar(userId: friendUserId, month: month, year: year, requestingUserId: requestingUserId)
		)

		switch result {
		case .success(let activities, _):
			// Log calendar activity details
			if !activities.isEmpty {
				print("📅 ProfileViewModel: Calendar activity details:")
				for (index, activity) in activities.enumerated() {
					print(
						"  \(index + 1). \(activity.date) - \(activity.icon ?? "No icon") - ID: \(activity.activityId?.uuidString ?? "No ID")"
					)
				}
			}

			let grid = convertToCalendarGrid(
				activities: activities,
				month: month,
				year: year
			)

			self.calendarActivities = grid
			self.allCalendarActivities = activities
			self.isLoadingCalendar = false

			// Pre-assign colors for calendar activities
			let activityIds = activities.compactMap { $0.activityId }
			ActivityColorService.shared.assignColorsForActivities(activityIds)

		case .failure(let error):
			print(
				"❌ ProfileViewModel: Error fetching friend's calendar activities: \(ErrorFormattingService.shared.formatError(error))"
			)
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			self.calendarActivities = Array(
				repeating: Array(repeating: nil, count: 7),
				count: 5
			)
			self.allCalendarActivities = []
			self.isLoadingCalendar = false
		}
	}

	private func convertToCalendarGrid(
		activities: [CalendarActivityDTO],
		month: Int,
		year: Int
	) -> [[CalendarActivityDTO?]] {
		var grid = Array(
			repeating: Array(repeating: nil as CalendarActivityDTO?, count: 7),
			count: 5
		)

		// Create the activities by day grid to be set on main thread later
		var newCalendarActivitiesByDay: [[[CalendarActivityDTO]]] = Array(
			repeating: Array(repeating: [], count: 7),
			count: 5
		)

		let firstDayOffset = firstDayOfMonth(month: month, year: year)

		// Group activities by day using local calendar for consistency
		let calendar = Calendar.current

		var activitiesByDay: [Int: [CalendarActivityDTO]] = [:]

		print("📅 ProfileViewModel: Converting \(activities.count) activities to calendar grid for \(month)/\(year)")

		for activity in activities {
			let activityMonth = calendar.component(.month, from: activity.dateAsDate)
			let activityYear = calendar.component(.year, from: activity.dateAsDate)

			// Only include activities from the specified month and year
			if activityMonth == month && activityYear == year {
				let day = calendar.component(.day, from: activity.dateAsDate)

				print("📅 ProfileViewModel: Including activity '\(activity.title ?? "No title")' on day \(day)")

				if activitiesByDay[day] == nil {
					activitiesByDay[day] = []
				}
				activitiesByDay[day]?.append(activity)
			} else {
				print(
					"📅 ProfileViewModel: Excluding activity '\(activity.title ?? "No title")' - wrong month/year (\(activityMonth)/\(activityYear))"
				)
			}
		}

		print("📅 ProfileViewModel: Grouped activities by day: \(activitiesByDay.keys.sorted())")

		// Place first activity of each day in the grid AND store all activities for each day
		for (day, dayActivities) in activitiesByDay {
			if !dayActivities.isEmpty {
				let position = day + firstDayOffset - 1
				if position >= 0 && position < 35 {
					let row = position / 7
					let col = position % 7
					grid[row][col] = dayActivities.first
					newCalendarActivitiesByDay[row][col] = dayActivities  // Store all activities for this day
					print(
						"📅 ProfileViewModel: Placed \(dayActivities.count) activities at grid position [\(row)][\(col)] for day \(day)"
					)
				}
			}
		}

		// Update the published property
		self.calendarActivitiesByDay = newCalendarActivitiesByDay

		return grid
	}

	private func dateFromString(_ dateString: String) -> Date? {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		return formatter.date(from: dateString)
	}

	private func extractDay(from date: Date) -> Int {
		return Calendar.current.component(.day, from: date)
	}

	private func firstDayOfMonth(month: Int, year: Int) -> Int {
		var components = DateComponents()
		components.year = year
		components.month = month
		components.day = 1

		let calendar = Calendar.current
		if let date = calendar.date(from: components) {
			let weekday = calendar.component(.weekday, from: date)
			// Convert from 1-7 (Sunday-Saturday) to 0-6 for our grid
			return weekday - 1
		}
		return 0
	}

	private func daysInMonth(month: Int, year: Int) -> Int {
		let calendar = Calendar.current
		var components = DateComponents()
		components.year = year
		components.month = month

		if let date = calendar.date(from: components),
			let range = calendar.range(of: .day, in: .month, for: date)
		{
			return range.count
		}
		return 30  // Default fallback
	}

	// MARK: - Calendar Helper Methods

	// Get all activities for a specific day position in the calendar grid
	func getActivitiesForDay(row: Int, col: Int) -> [CalendarActivityDTO] {
		guard row >= 0 && row < calendarActivitiesByDay.count && col >= 0 && col < calendarActivitiesByDay[row].count
		else {
			return []
		}
		return calendarActivitiesByDay[row][col]
	}

	// MARK: - Interest Management

	// Save original interests state when entering edit mode
	func saveOriginalInterests() {
		originalUserInterests = userInterests
	}

	// Restore original interests state when canceling edit mode
	func restoreOriginalInterests() {
		userInterests = originalUserInterests
	}

	// Interest management methods
	func removeUserInterest(userId: UUID, interest: String) async {
		// Store original state for potential rollback
		let originalInterests = userInterests

		// Update local state immediately for better UX
		self.userInterests.removeAll { $0 == interest }

		// URL encode the interest name to handle spaces and special characters
		guard let encodedInterest = interest.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
			self.userInterests = originalInterests
			self.errorMessage = "Failed to encode interest name"
			return
		}

		let operation = WriteOperation<EmptyRequestBody>.delete(
			endpoint: "users/\(userId)/interests/\(encodedInterest)",
			cacheInvalidationKeys: ["profileInterests_\(userId)"]
		)

		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(operation)

		switch result {
		case .success:
			// Refresh interests from server after successful delete
			let refreshResult: DataResult<[String]> = await dataService.read(
				.profileInterests(userId: userId),
				cachePolicy: .apiOnly
			)

			if case .success(let interests, _) = refreshResult {
				self.userInterests = interests
			}

		case .failure(let error):
			print("❌ Failed to remove interest '\(interest)': \(ErrorFormattingService.shared.formatError(error))")

			// Revert the optimistic update since the API call failed
			self.userInterests = originalInterests
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
		}
	}

	// Method for edit profile flow - doesn't revert local state on error
	func removeUserInterestForEdit(userId: UUID, interest: String) async {
		// URL encode the interest name to handle spaces and special characters
		guard let encodedInterest = interest.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
			print("❌ Failed to encode interest name: \(interest)")
			return
		}

		let operation = WriteOperation<EmptyRequestBody>.delete(
			endpoint: "users/\(userId)/interests/\(encodedInterest)",
			cacheInvalidationKeys: ["profileInterests_\(userId)"]
		)

		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(operation)

		switch result {
		case .success:
			// Refresh interests from cache
			let _: DataResult<[String]> = await dataService.read(
				.profileInterests(userId: userId), cachePolicy: .apiOnly)

		case .failure(let error):
			print("❌ Failed to remove interest '\(interest)': \(ErrorFormattingService.shared.formatError(error))")
		// For other errors, we could show a warning but still keep the local state
		// since the user explicitly wanted to remove it
		}
	}

	// MARK: - Activity Management

	func fetchActivityDetails(activityId: UUID) async -> FullFeedActivityDTO? {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("❌ ProfileViewModel: No user ID available for activity details")
			self.errorMessage = "User ID not available"
			return nil
		}

		print("🔄 ProfileViewModel: Fetching activity details for activity: \(activityId)")

		self.isLoadingActivity = true

		// Use centralized DataType configuration
		let result: DataResult<FullFeedActivityDTO> = await dataService.read(
			.activity(activityId: activityId, requestingUserId: userId)
		)

		switch result {
		case .success(let activity, _):
			print(
				"📋 Activity Details: ID: \(activity.id), Title: \(activity.title ?? "No title"), Location: \(activity.location?.name ?? "No location")"
			)

			self.selectedActivity = activity
			self.isLoadingActivity = false

			return activity

		case .failure(let error):
			print(
				"❌ ProfileViewModel: Error fetching activity details: \(ErrorFormattingService.shared.formatError(error))"
			)
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			self.isLoadingActivity = false
			return nil
		}
	}

	// MARK: - Friendship Management

	/// Sets friendship status from a RecommendedFriendUserDTO, eliminating the need for an extra API call
	func setFriendshipStatusFromRecommendedFriend(_ recommendedFriend: RecommendedFriendUserDTO) {
		guard let relationshipStatus = recommendedFriend.relationshipStatus else {
			self.friendshipStatus = .unknown
			return
		}

		let friendshipStatus: FriendshipStatus
		switch relationshipStatus {
		case .friend:
			friendshipStatus = .friends
		case .recommendedFriend:
			friendshipStatus = .none
		case .incomingFriendRequest:
			friendshipStatus = .requestReceived
		case .outgoingFriendRequest:
			friendshipStatus = .requestSent
		}

		self.friendshipStatus = friendshipStatus
		self.pendingFriendRequestId = recommendedFriend.pendingFriendRequestId
	}

	func checkFriendshipStatus(currentUserId: UUID, profileUserId: UUID) async {
		// Don't check if it's the current user's profile
		if currentUserId == profileUserId {
			self.friendshipStatus = .themself
			return
		}

		self.isLoadingFriendshipStatus = true

		// First check if users are friends using centralized config
		let friendResult: DataResult<Bool> = await dataService.read(
			.isFriend(currentUserId: currentUserId, otherUserId: profileUserId)
		)

		switch friendResult {
		case .success(let isFriend, _):
			if isFriend {
				self.friendshipStatus = .friends
				self.isLoadingFriendshipStatus = false
				return
			}

			// If not friends, check for pending friend requests in parallel
			async let incomingResult: DataResult<[FetchFriendRequestDTO]> = dataService.read(
				.friendRequests(userId: currentUserId))
			async let profileIncomingResult: DataResult<[FetchFriendRequestDTO]> = dataService.read(
				.friendRequests(userId: profileUserId))

			// Wait for both requests to complete
			let (currentUserRequestsResult, profileUserRequestsResult) = await (incomingResult, profileIncomingResult)

			var currentUserRequests: [FetchFriendRequestDTO] = []
			var profileUserRequests: [FetchFriendRequestDTO] = []

			if case .success(let requests, _) = currentUserRequestsResult {
				currentUserRequests = requests
			}

			if case .success(let requests, _) = profileUserRequestsResult {
				profileUserRequests = requests
			}

			// Check if any incoming request is from the profile user
			let requestFromProfileUser = currentUserRequests.first { $0.senderUser.id == profileUserId }

			if let requestFromProfileUser = requestFromProfileUser {
				let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
				self.friendshipStatus = .requestReceived
				self.pendingFriendRequestId =
					(requestFromProfileUser.id == zeroUUID) ? nil : requestFromProfileUser.id
				self.isLoadingFriendshipStatus = false
				return
			}

			// Check if any incoming request to profile user is from current user
			let requestToProfileUser = profileUserRequests.first { $0.senderUser.id == currentUserId }

			if requestToProfileUser != nil {
				self.friendshipStatus = .requestSent
			} else {
				self.friendshipStatus = .none
			}
			self.isLoadingFriendshipStatus = false

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			self.friendshipStatus = .unknown
			self.isLoadingFriendshipStatus = false
		}
	}

	func sendFriendRequest(fromUserId: UUID, toUserId: UUID) async {
		let requestDTO = CreateFriendRequestDTO(
			id: UUID(),
			senderUserId: fromUserId,
			receiverUserId: toUserId
		)

		// Use WriteOperationType configuration
		let operationType = WriteOperationType.sendFriendRequest(request: requestDTO)
		let result: DataResult<CreateFriendRequestDTO> = await dataService.write(operationType, body: requestDTO)

		switch result {
		case .success:
			self.friendshipStatus = .requestSent
			// Refresh recommended friends to update the list
			let _: DataResult<[RecommendedFriendUserDTO]> = await dataService.read(
				.recommendedFriends(userId: fromUserId), cachePolicy: .apiOnly)

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
		}
	}

	func acceptFriendRequest(requestId: UUID) async {
		// IMMEDIATELY update UI state to provide instant feedback
		self.friendshipStatus = .friends
		self.pendingFriendRequestId = nil

		print("[PROFILE] accepted friend request id=\(requestId) -> status=friends")
		NotificationCenter.default.post(name: .friendRequestsDidChange, object: nil)

		// Use WriteOperationType configuration
		let operationType = WriteOperationType.acceptFriendRequest(requestId: requestId)
		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(operationType)

		switch result {
		case .success:
			// Refresh friends list to update the cache
			if let userId = UserAuthViewModel.shared.spawnUser?.id {
				let _: DataResult<[FullFriendUserDTO]> = await dataService.read(
					.friends(userId: userId), cachePolicy: .apiOnly)
				let _: DataResult<[FetchFriendRequestDTO]> = await dataService.read(
					.friendRequests(userId: userId), cachePolicy: .apiOnly)
			}
			NotificationCenter.default.post(name: .friendsDidChange, object: nil)

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			// Revert the optimistic update on failure
			self.friendshipStatus = .requestReceived
			self.pendingFriendRequestId = requestId
		}
	}

	func declineFriendRequest(requestId: UUID) async {
		// IMMEDIATELY update UI state to provide instant feedback
		self.friendshipStatus = .none
		self.pendingFriendRequestId = nil

		NotificationCenter.default.post(name: .friendRequestsDidChange, object: nil)

		// Use WriteOperationType configuration
		let operationType = WriteOperationType.declineFriendRequest(requestId: requestId)
		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(operationType)

		switch result {
		case .success:
			// Successfully declined
			break

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			// Revert the optimistic update on failure
			self.friendshipStatus = .requestReceived
			self.pendingFriendRequestId = requestId
		}
	}

	// MARK: - User Activities

	func fetchUserUpcomingActivities(userId: UUID) async {
		self.isLoadingUserActivities = true

		// Use centralized DataType configuration
		let result: DataResult<[FullFeedActivityDTO]> = await dataService.read(
			.upcomingActivities(userId: userId)
		)

		switch result {
		case .success(let activities, _):
			self.userActivities = activities
			self.isLoadingUserActivities = false

			// Pre-assign colors for user activities
			let activityIds = activities.map { $0.id }
			ActivityColorService.shared.assignColorsForActivities(activityIds)

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			self.userActivities = []
			self.isLoadingUserActivities = false
		}
	}

	// New method to fetch profile activities (both upcoming and past)
	func fetchProfileActivities(profileUserId: UUID) async {
		print("🔄 ProfileViewModel: Fetching profile activities for user: \(profileUserId)")

		let result: DataResult<[ProfileActivityDTO]> = await dataService.read(
			.profileActivities(userId: profileUserId),
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let activities, _):
			// Log activity details
			if !activities.isEmpty {
				print("📋 ProfileViewModel: Activity details:")
				for (index, activity) in activities.enumerated() {
					print(
						"  \(index + 1). \(activity.title ?? "No title") - \(activity.startTime?.formatted() ?? "No time")"
					)
				}
			}

			self.profileActivities = activities
			self.isLoadingUserActivities = false

		case .failure(let error):
			print(
				"❌ ProfileViewModel: Error fetching profile activities: \(ErrorFormattingService.shared.formatError(error))"
			)
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			self.profileActivities = []
			self.isLoadingUserActivities = false
		}
	}

	// MARK: - Friend Management

	func removeFriend(currentUserId: UUID, profileUserId: UUID) async {
		let operation = WriteOperation<EmptyRequestBody>.delete(
			endpoint: "api/v1/users/friends/\(currentUserId)/\(profileUserId)",
			cacheInvalidationKeys: ["friends_\(currentUserId)"]
		)

		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(operation)

		switch result {
		case .success:
			self.friendshipStatus = .none
			// Refresh friends list
			let _: DataResult<[FullFriendUserDTO]> = await dataService.read(
				.friends(userId: currentUserId), cachePolicy: .apiOnly)

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
		}
	}

	func reportUser(reporterUserId: UUID, reportedUserId: UUID, reportType: ReportType, description: String) async {
		let reportDTO = CreateReportedContentDTO(
			reporterUserId: reporterUserId,
			contentId: reportedUserId,
			contentType: .user,
			reportType: reportType,
			description: description
		)

		// Use DataService with WriteOperationType
		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(
			.reportUser(report: reportDTO)
		)

		switch result {
		case .success:
			self.errorMessage = nil
		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
		}
	}

	/// Legacy method for backward compatibility
	/// - Deprecated: Use reportUser(reporterUserId:reportedUserId:reportType:description:) instead
	@available(*, deprecated, message: "Use reportUser(reporterUserId:reportedUserId:reportType:description:) instead")
	func reportUser(reporter: UserDTO, reportedUser: UserDTO, reportType: ReportType, description: String) async {
		await reportUser(
			reporterUserId: reporter.id,
			reportedUserId: reportedUser.id,
			reportType: reportType,
			description: description
		)
	}

	func blockUser(blockerId: UUID, blockedId: UUID, reason: String) async {
		// Use DataService with WriteOperationType
		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(
			.blockUser(blockerId: blockerId, blockedId: blockedId, reason: reason)
		)

		switch result {
		case .success:
			self.friendshipStatus = .blocked
			self.errorMessage = nil

			// Refresh friends cache to remove the blocked user from friends list
			// Trigger via DataService read with apiOnly to refresh cache
			if let userId = UserAuthViewModel.shared.spawnUser?.id {
				let _: DataResult<[FullFriendUserDTO]> = await dataService.read(
					.friends(userId: userId), cachePolicy: .apiOnly)
			}

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
		}
	}

	func unblockUser(blockerId: UUID, blockedId: UUID) async {
		// Use DataService with WriteOperationType
		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(
			.unblockUser(blockerId: blockerId, blockedId: blockedId)
		)

		switch result {
		case .success:
			self.friendshipStatus = .none
			self.errorMessage = nil

			// Refresh friends cache for consistency via DataService
			if let userId = UserAuthViewModel.shared.spawnUser?.id {
				let _: DataResult<[FullFriendUserDTO]> = await dataService.read(
					.friends(userId: userId), cachePolicy: .apiOnly)
			}

		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
		}
	}

	func checkIfUserBlocked(blockerId: UUID, blockedId: UUID) async -> Bool {
		// Use DataService with DataType
		let result: DataResult<Bool> = await dataService.read(
			.isUserBlocked(blockerId: blockerId, blockedId: blockedId),
			cachePolicy: .apiOnly
		)

		switch result {
		case .success(let isBlocked, _):
			return isBlocked
		case .failure(let error):
			self.errorMessage = ErrorFormattingService.shared.formatError(error)
			return false
		}
	}
}

// Enum to represent friendship status
enum FriendshipStatus {
	case unknown  // Status not yet determined
	case none  // Not friends
	case friends  // Already friends
	case requestSent  // Current user sent request to profile user
	case requestReceived  // Profile user sent request to current user
	case themself  // It's the current user's own profile
	case blocked  // User is blocked
}
