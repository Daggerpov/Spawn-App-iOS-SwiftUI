import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var userStats: UserStatsDTO?
    @Published var userInterests: [String] = []
    @Published var originalUserInterests: [String] = [] // Backup for cancel functionality
    @Published var userSocialMedia: UserSocialMediaDTO?
    @Published var userProfileInfo: UserProfileInfoDTO?
    @Published var isLoadingStats: Bool = false
    @Published var isLoadingInterests: Bool = false
    @Published var isLoadingSocialMedia: Bool = false
    @Published var isLoadingProfileInfo: Bool = false
    @Published var showDrawer: Bool = false
    @Published var errorMessage: String?
    @Published var calendarActivities: [[CalendarActivityDTO?]] = Array(
        repeating: Array(repeating: nil, count: 7),
        count: 5
    )
    @Published var isLoadingCalendar: Bool = false
    @Published var allCalendarActivities: [CalendarActivityDTO] = []
    @Published var selectedActivity: FullFeedActivityDTO?
    @Published var isLoadingActivity: Bool = false
    
    // New property to store all activities organized by day position in the grid
    @Published var calendarActivitiesByDay: [[[CalendarActivityDTO]]] = Array(
        repeating: Array(repeating: [CalendarActivityDTO](), count: 7),
        count: 5
    )
    
    // New properties for friendship status
	@Published var friendshipStatus: FriendshipStatus = MockAPIService.isMocking ? .friends : .unknown
    @Published var isLoadingFriendshipStatus: Bool = false
    @Published var pendingFriendRequestId: UUID?
    @Published var userActivities: [FullFeedActivityDTO] = []
    @Published var profileActivities: [ProfileActivityDTO] = []
    @Published var isLoadingUserActivities: Bool = false
    
    private let apiService: IAPIService
    
    init(
        userId: UUID? = nil,
        apiService: IAPIService? = nil
    ) {
        if let apiService = apiService {
            self.apiService = apiService
        } else {
            self.apiService = MockAPIService.isMocking
                ? MockAPIService(userId: userId) : APIService()
        }
    }
    
    func fetchUserStats(userId: UUID) async {
        await MainActor.run { self.isLoadingStats = true }
        
        // Check cache first
        if let cachedStats = AppCache.shared.profileStats[userId] {
            await MainActor.run {
                self.userStats = cachedStats
                self.isLoadingStats = false
            }
            return
        }
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/stats")!
            let stats: UserStatsDTO = try await self.apiService.fetchData(
                from: url,
                parameters: nil
            )
            
            await MainActor.run {
                self.userStats = stats
                self.isLoadingStats = false
                // Update cache
                AppCache.shared.updateProfileStats(userId, stats)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load user stats: \(error.localizedDescription)"
                self.isLoadingStats = false
            }
        }
    }
    
    func fetchUserInterests(userId: UUID) async {
        await MainActor.run { self.isLoadingInterests = true }
        
        // Check cache first
        if let cachedInterests = AppCache.shared.profileInterests[userId] {
            await MainActor.run {
                self.userInterests = cachedInterests
                self.isLoadingInterests = false
            }
            return
        }
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/interests")!
            let interests: [String] = try await self.apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                self.userInterests = interests
                self.isLoadingInterests = false
                // Update cache
                AppCache.shared.updateProfileInterests(userId, interests)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load user interests: \(error.localizedDescription)"
                self.isLoadingInterests = false
            }
        }
    }
    
    func addUserInterest(userId: UUID, interest: String) async -> Bool {
        // Update local state immediately for better UX
        await MainActor.run {
            self.userInterests.append(interest)
        }
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/interests")!
            
            // Send interest as raw string data instead of JSON-encoded
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = interest.data(using: .utf8)
            
            // Add authorization header
            if let accessTokenData = KeychainService.shared.load(key: "accessToken"),
               let accessToken = String(data: accessTokenData, encoding: .utf8) {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "HTTPError", code: 0, userInfo: [NSLocalizedDescriptionKey: "HTTP request failed"])
            }
            
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Invalid status code: \(httpResponse.statusCode)"])
            }
            
            // Update cache after successful API call
            await AppCache.shared.refreshProfileInterests(userId)
            return true
        } catch {
            // Revert local state if API call fails
            await MainActor.run {
                self.userInterests.removeAll { $0 == interest }
                self.errorMessage = "Failed to add interest: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    func fetchUserSocialMedia(userId: UUID) async {
        await MainActor.run { self.isLoadingSocialMedia = true }
        
        // Check cache first
        if let cachedSocialMedia = AppCache.shared.profileSocialMedia[userId] {
            await MainActor.run {
                self.userSocialMedia = cachedSocialMedia
                self.isLoadingSocialMedia = false
            }
            return
        }
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/social-media")!
            let socialMedia: UserSocialMediaDTO = try await self.apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                self.userSocialMedia = socialMedia
                self.isLoadingSocialMedia = false
                // Update cache
                AppCache.shared.updateProfileSocialMedia(userId, socialMedia)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load social media: \(error.localizedDescription)"
                self.isLoadingSocialMedia = false
            }
        }
    }
    
    func updateSocialMedia(
        userId: UUID,
        whatsappLink: String?,
        instagramLink: String?
    ) async {
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/social-media")!
            let updateDTO = UpdateUserSocialMediaDTO(
                whatsappNumber: whatsappLink,
                instagramUsername: instagramLink
            )
            
            let updatedSocialMedia: UserSocialMediaDTO = try await self.apiService.updateData(
                updateDTO,
                to: url,
                parameters: nil
            )
            
            await MainActor.run {
                self.userSocialMedia = updatedSocialMedia
                // Update cache
                AppCache.shared.updateProfileSocialMedia(userId, updatedSocialMedia)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update social media: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchUserProfileInfo(userId: UUID) async {
        await MainActor.run { self.isLoadingProfileInfo = true }
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/profile-info")!
            let profileInfo: UserProfileInfoDTO = try await self.apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                self.userProfileInfo = profileInfo
                self.isLoadingProfileInfo = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load profile info: \(error.localizedDescription)"
                self.isLoadingProfileInfo = false
            }
        }
    }
    
    func loadAllProfileData(userId: UUID) async {
        await fetchUserStats(userId: userId)
        await fetchUserInterests(userId: userId)
        await fetchUserSocialMedia(userId: userId)
        await fetchUserProfileInfo(userId: userId)
    }
    
    func fetchCalendarActivities(month: Int, year: Int) async {
        await MainActor.run { self.isLoadingCalendar = true }
        
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            await MainActor.run {
                self.isLoadingCalendar = false
                self.errorMessage = "User ID not available"
            }
            return
        }
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/calendar")!
            let parameters = [
                "month": String(month),
                "year": String(year),
            ]
            
            let activities: [CalendarActivityDTO] = try await apiService.fetchData(
                from: url,
                parameters: parameters
            )
            
            let grid = convertToCalendarGrid(
                activities: activities,
                month: month,
                year: year
            )
            
            await MainActor.run {
                self.calendarActivities = grid
                self.isLoadingCalendar = false
                
                // Pre-assign colors for calendar activities
                let activityIds = activities.compactMap { $0.activityId }
                ActivityColorService.shared.assignColorsForActivities(activityIds)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load calendar: \(error.localizedDescription)"
                self.calendarActivities = Array(
                    repeating: Array(repeating: nil, count: 7),
                    count: 5
                )
                self.isLoadingCalendar = false
            }
        }
    }
    
    func fetchAllCalendarActivities() async {
        await MainActor.run { self.isLoadingCalendar = true }
        
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            await MainActor.run {
                self.isLoadingCalendar = false
                self.errorMessage = "User ID not available"
            }
            return
        }
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/calendar")!
            let activities: [CalendarActivityDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                self.allCalendarActivities = activities
                self.isLoadingCalendar = false
                
                // Pre-assign colors for calendar activities
                let activityIds = activities.compactMap { $0.activityId }
                ActivityColorService.shared.assignColorsForActivities(activityIds)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load calendar: \(error.localizedDescription)"
                self.allCalendarActivities = []
                self.isLoadingCalendar = false
            }
        }
    }
    
    // Method to fetch all calendar activities for a friend
    func fetchAllCalendarActivities(friendUserId: UUID) async {
        await MainActor.run { self.isLoadingCalendar = true }
        
        guard let requestingUserId = UserAuthViewModel.shared.spawnUser?.id else {
            print("❌ ProfileViewModel: No requesting user ID available for calendar activities")
            await MainActor.run {
                self.isLoadingCalendar = false
                self.errorMessage = "User ID not available"
            }
            return
        }
        
        print("🔄 ProfileViewModel: Fetching all calendar activities for friend: \(friendUserId)")
        print("📡 API Mode: \(MockAPIService.isMocking ? "MOCK" : "REAL")")
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(friendUserId)/calendar")!
            let parameters = [
                "requestingUserId": requestingUserId.uuidString
            ]
            
            print("📡 ProfileViewModel: Making calendar API call to: \(url.absoluteString)")
            print("📡 ProfileViewModel: Parameters: \(parameters)")
            
            let activities: [CalendarActivityDTO] = try await apiService.fetchData(
                from: url,
                parameters: parameters
            )
            
            print("✅ ProfileViewModel: Successfully fetched \(activities.count) calendar activities")
            
            await MainActor.run {
                self.allCalendarActivities = activities
                self.isLoadingCalendar = false
                
                // Pre-assign colors for calendar activities
                let activityIds = activities.compactMap { $0.activityId }
                ActivityColorService.shared.assignColorsForActivities(activityIds)
                
                print("✅ ProfileViewModel: All calendar activities updated with \(activities.count) activities")
            }
        } catch {
            print("❌ ProfileViewModel: Error fetching friend's all calendar activities: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to load friend's calendar: \(error.localizedDescription)"
                self.allCalendarActivities = []
                self.isLoadingCalendar = false
            }
        }
    }
    
    // Method to fetch friend's calendar activities
    func fetchFriendCalendarActivities(friendUserId: UUID, month: Int, year: Int) async {
        await MainActor.run { self.isLoadingCalendar = true }
        
        guard let requestingUserId = UserAuthViewModel.shared.spawnUser?.id else {
            print("❌ ProfileViewModel: No requesting user ID available for calendar activities")
            await MainActor.run {
                self.isLoadingCalendar = false
                self.errorMessage = "User ID not available"
            }
            return
        }
        
        print("🔄 ProfileViewModel: Fetching calendar activities for friend: \(friendUserId)")
        print("📡 API Mode: \(MockAPIService.isMocking ? "MOCK" : "REAL")")
        print("📅 Month: \(month), Year: \(year)")
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(friendUserId)/calendar")!
            let parameters = [
                "month": String(month),
                "year": String(year),
                "requestingUserId": requestingUserId.uuidString
            ]
            
            print("📡 ProfileViewModel: Making calendar API call to: \(url.absoluteString)")
            print("📡 ProfileViewModel: Parameters: \(parameters)")
            
            let activities: [CalendarActivityDTO] = try await apiService.fetchData(
                from: url,
                parameters: parameters
            )
            

            
            // Log calendar activity details
            if !activities.isEmpty {
                print("📅 ProfileViewModel: Calendar activity details:")
                for (index, activity) in activities.enumerated() {
                    print("  \(index + 1). \(activity.date.formatted()) - \(activity.icon ?? "No icon") - ID: \(activity.activityId?.uuidString ?? "No ID")")
                }
            }
            
            let grid = convertToCalendarGrid(
                activities: activities,
                month: month,
                year: year
            )
            
            await MainActor.run {
				print("✅ ProfileViewModel: Successfully fetched \(activities.count) calendar activities")

                self.calendarActivities = grid
                self.allCalendarActivities = activities
                self.isLoadingCalendar = false
                
                // Pre-assign colors for calendar activities
                let activityIds = activities.compactMap { $0.activityId }
                ActivityColorService.shared.assignColorsForActivities(activityIds)
                
                print("✅ ProfileViewModel: Calendar grid updated with \(activities.count) activities")
            }
        } catch {
            print("❌ ProfileViewModel: Error fetching friend's calendar activities: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to load friend's calendar: \(error.localizedDescription)"
                self.calendarActivities = Array(
                    repeating: Array(repeating: nil, count: 7),
                    count: 5
                )
                self.allCalendarActivities = []
                self.isLoadingCalendar = false
            }
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
        
        // Group activities by day
        var activitiesByDay: [Int: [CalendarActivityDTO]] = [:]
        
        for activity in activities {
            let activityMonth = Calendar.current.component(
                .month,
                from: activity.date
            )
            let activityYear = Calendar.current.component(
                .year,
                from: activity.date
            )
            
            // Only include activities from the specified month and year
            if activityMonth == month && activityYear == year {
                let day = Calendar.current.component(.day, from: activity.date)
                
                if activitiesByDay[day] == nil {
                    activitiesByDay[day] = []
                }
                activitiesByDay[day]?.append(activity)
            }
        }
        
        // Place first activity of each day in the grid AND store all activities for each day
        for (day, dayActivities) in activitiesByDay {
            if !dayActivities.isEmpty {
                let position = day + firstDayOffset - 1
                if position >= 0 && position < 35 {
                    let row = position / 7
                    let col = position % 7
                    grid[row][col] = dayActivities.first
                    newCalendarActivitiesByDay[row][col] = dayActivities // Store all activities for this day
                }
            }
        }
        
        // Update the published property on the main thread
        Task { @MainActor in
            self.calendarActivitiesByDay = newCalendarActivitiesByDay
        }
        
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
        guard row >= 0 && row < calendarActivitiesByDay.count &&
              col >= 0 && col < calendarActivitiesByDay[row].count else {
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
        // Update local state immediately for better UX
        await MainActor.run {
            self.userInterests.removeAll { $0 == interest }
        }
        
        do {
            // URL encode the interest name to handle spaces and special characters
            guard let encodedInterest = interest.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                throw NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode interest name"])
            }
            
            let url = URL(string: APIService.baseURL + "users/\(userId)/interests/\(encodedInterest)")!
            print("Attempting to delete interest at URL: \(url)")
            
            let _ = try await apiService.deleteData(
                from: url,
                parameters: nil,
                object: EmptyObject()
            )
            
            print("Successfully deleted interest: \(interest)")
            
            // Update cache after successful API call - commented out for now
            // await AppCache.shared.refreshProfileInterests(userId)
        } catch {
            // Add debug information
            print("Failed to remove interest '\(interest)': \(error.localizedDescription)")
            
            // Don't revert local state for now - let the user see immediate feedback
            // We'll handle the UI optimistically
            await MainActor.run {
                self.errorMessage = "Failed to remove interest: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Activity Management
    
    func fetchActivityDetails(activityId: UUID) async -> FullFeedActivityDTO? {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("❌ ProfileViewModel: No user ID available for activity details")
            await MainActor.run {
                self.errorMessage = "User ID not available"
            }
            return nil
        }
        
        print("🔄 ProfileViewModel: Fetching activity details for activity: \(activityId)")
        print("📡 API Mode: \(MockAPIService.isMocking ? "MOCK" : "REAL")")
        
        await MainActor.run { self.isLoadingActivity = true }
        
        do {
            let url = URL(string: APIService.baseURL + "activities/\(activityId)")!
            let parameters = ["requestingUserId": userId.uuidString]
            
            print("📡 ProfileViewModel: Making activity details API call to: \(url.absoluteString)")
            print("📡 ProfileViewModel: Parameters: \(parameters)")
            
            let activity: FullFeedActivityDTO = try await apiService.fetchData(
                from: url,
                parameters: parameters
            )
            
            print("✅ ProfileViewModel: Successfully fetched activity details: \(activity.title ?? "No title")")
            print("📋 Activity Details: ID: \(activity.id), Title: \(activity.title ?? "No title"), Location: \(activity.location?.name ?? "No location")")
            
            await MainActor.run {
                self.selectedActivity = activity
                self.isLoadingActivity = false
            }
            
            return activity
        } catch {
            print("❌ ProfileViewModel: Error fetching activity details: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to load activity: \(error.localizedDescription)"
                self.isLoadingActivity = false
            }
            return nil
        }
    }
    
    // MARK: - Friendship Management
    
    func checkFriendshipStatus(currentUserId: UUID, profileUserId: UUID) async {
        // Don't check if it's the current user's profile
        if currentUserId == profileUserId {
            await MainActor.run {
                self.friendshipStatus = .themself
            }
            return
        }
        
        await MainActor.run { self.isLoadingFriendshipStatus = true }
        
        do {
            // First check if users are friends
            let url = URL(string: APIService.baseURL + "users/\(currentUserId)/is-friend/\(profileUserId)")!
			let isFriend: Bool = try await self.apiService.fetchData(
				from: url,
				parameters: nil
			)

            if isFriend {
                await MainActor.run {
                    self.friendshipStatus = .friends
                    self.isLoadingFriendshipStatus = false
                }
                return
            }
            
            // If not friends, check for pending friend requests
            // Check if current user has received a friend request from the profile user
            let incomingRequestsUrl = URL(string: APIService.baseURL + "friend-requests/incoming/\(currentUserId)")!
            let incomingRequests: [FetchFriendRequestDTO] = try await self.apiService.fetchData(from: incomingRequestsUrl, parameters: nil)
            
            // Check if any incoming request is from the profile user
            let requestFromProfileUser = incomingRequests.first { $0.senderUser.id == profileUserId }
            
            if let requestFromProfileUser = requestFromProfileUser {
                await MainActor.run {
                    self.friendshipStatus = .requestReceived
                    self.pendingFriendRequestId = requestFromProfileUser.id
                    self.isLoadingFriendshipStatus = false
                }
                return
            }
            
            // Check if profile user has received a friend request from current user
            let profileUserIncomingUrl = URL(string: APIService.baseURL + "friend-requests/incoming/\(profileUserId)")!
            let profileUserIncomingRequests: [FetchFriendRequestDTO] = try await self.apiService.fetchData(from: profileUserIncomingUrl, parameters: nil)
            
            // Check if any incoming request to profile user is from current user
            let requestToProfileUser = profileUserIncomingRequests.first { $0.senderUser.id == currentUserId }
            
            await MainActor.run {
                if requestToProfileUser != nil {
                    self.friendshipStatus = .requestSent
                } else {
                    self.friendshipStatus = .none
                }
                self.isLoadingFriendshipStatus = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to check friendship status: \(error.localizedDescription)"
                self.friendshipStatus = .unknown
                self.isLoadingFriendshipStatus = false
            }
        }
    }
    
    func sendFriendRequest(fromUserId: UUID, toUserId: UUID) async {
        do {
            let url = URL(string: APIService.baseURL + "friend-requests")!
            let requestDTO = CreateFriendRequestDTO(
                id: UUID(),
                senderUserId: fromUserId,
                receiverUserId: toUserId
            )
            
            guard let _: CreateFriendRequestDTO = try await self.apiService.sendData(
                requestDTO,
                to: url,
                parameters: nil
            ) else {return}
            
            await MainActor.run {
                self.friendshipStatus = .requestSent
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to send friend request: \(error.localizedDescription)"
            }
        }
    }
    
    func acceptFriendRequest(requestId: UUID) async {
        do {
            let url = URL(string: APIService.baseURL + "friend-requests/\(requestId)")!
            let _: EmptyResponse = try await self.apiService.updateData(
                EmptyRequestBody(),
                to: url,
                parameters: ["friendRequestAction": "accept"]
            )
            
            await MainActor.run {
                self.friendshipStatus = .friends
                self.pendingFriendRequestId = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to accept friend request: \(error.localizedDescription)"
            }
        }
    }
    
    func declineFriendRequest(requestId: UUID) async {
        do {
            let url = URL(string: APIService.baseURL + "friend-requests/\(requestId)")!
            let _: EmptyResponse = try await self.apiService.updateData(
                EmptyRequestBody(),
                to: url,
                parameters: ["friendRequestAction": "reject"]
            )
            
            await MainActor.run {
                self.friendshipStatus = .none
                self.pendingFriendRequestId = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to decline friend request: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - User Activities
    
    func fetchUserUpcomingActivities(userId: UUID) async {
        await MainActor.run { self.isLoadingUserActivities = true }
        
        do {
            let url = URL(string: APIService.baseURL + "activities/user/\(userId)/upcoming")!
            let activities: [FullFeedActivityDTO] = try await self.apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                self.userActivities = activities
                self.isLoadingUserActivities = false
                
                // Pre-assign colors for user activities
                let activityIds = activities.map { $0.id }
                ActivityColorService.shared.assignColorsForActivities(activityIds)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load user activities: \(error.localizedDescription)"
                self.userActivities = []
                self.isLoadingUserActivities = false
            }
        }
    }
    
    // New method to fetch profile activities (both upcoming and past)
    func fetchProfileActivities(profileUserId: UUID) async {
        guard let requestingUserId = UserAuthViewModel.shared.spawnUser?.id else {
            print("❌ ProfileViewModel: No requesting user ID available")
            await MainActor.run {
                self.errorMessage = "User ID not available"
            }
            return
        }
        
        print("🔄 ProfileViewModel: Fetching profile activities for user: \(profileUserId)")
        print("📡 API Mode: \(MockAPIService.isMocking ? "MOCK" : "REAL")")
        
        await MainActor.run { self.isLoadingUserActivities = true }
        
        // Check cache first
        if let cachedActivities = AppCache.shared.profileActivities[profileUserId] {
            print("💾 ProfileViewModel: Found cached profile activities: \(cachedActivities.count)")
            await MainActor.run {
                self.profileActivities = cachedActivities
                self.isLoadingUserActivities = false
            }
            return
        }
        
        do {
            let url = URL(string: APIService.baseURL + "activities/profile/\(profileUserId)")!
            let parameters = ["requestingUserId": requestingUserId.uuidString]
            
            print("📡 ProfileViewModel: Making API call to: \(url.absoluteString)")
            print("📡 ProfileViewModel: Parameters: \(parameters)")
            
            let activities: [ProfileActivityDTO] = try await self.apiService.fetchData(
                from: url,
                parameters: parameters
            )
            
            print("✅ ProfileViewModel: Successfully fetched \(activities.count) profile activities")
            
            // Log activity details
            if !activities.isEmpty {
                print("📋 ProfileViewModel: Activity details:")
                for (index, activity) in activities.enumerated() {
                    print("  \(index + 1). \(activity.title ?? "No title") - \(activity.startTime?.formatted() ?? "No time")")
                }
            }
            
            await MainActor.run {
                self.profileActivities = activities
                self.isLoadingUserActivities = false
                // Update cache
                AppCache.shared.updateProfileActivities(profileUserId, activities)
            }
        } catch {
            print("❌ ProfileViewModel: Error fetching profile activities: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to load profile activities: \(error.localizedDescription)"
                self.profileActivities = []
                self.isLoadingUserActivities = false
            }
        }
    }
    
    // MARK: - Friend Management
    
    func removeFriend(currentUserId: UUID, profileUserId: UUID) async {
        do {
            let url = URL(string: APIService.baseURL + "blocked-users/remove-friendship")!
            let parameters = [
                "userAId": currentUserId.uuidString,
                "userBId": profileUserId.uuidString
            ]
            
            // Discard the return value since we don't need it
            _ = try await self.apiService.sendData(
                EmptyRequestBody(),
                to: url,
                parameters: parameters
            )
            
            await MainActor.run {
                self.friendshipStatus = .none
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to remove friend: \(error.localizedDescription)"
            }
        }
    }
    
    func reportUser(reporterUserId: UUID, reportedUserId: UUID, reportType: ReportType, description: String) async {
        do {
            let reportingService = UserReportingService(apiService: self.apiService)
            try await reportingService.reportUser(
                reporterUserId: reporterUserId,
                reportedUserId: reportedUserId,
                reportType: reportType,
                description: description
            )
            
            await MainActor.run {
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to report user: \(error.localizedDescription)"
            }
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
        do {
            let reportingService = UserReportingService(apiService: self.apiService)
            try await reportingService.blockUser(
                blockerId: blockerId,
                blockedId: blockedId,
                reason: reason
            )
            
            await MainActor.run {
                self.friendshipStatus = .blocked
                self.errorMessage = nil
            }
            
            // Refresh friends cache to remove the blocked user from friends list
            await AppCache.shared.refreshFriends()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to block user: \(error.localizedDescription)"
            }
        }
    }
    
    func unblockUser(blockerId: UUID, blockedId: UUID) async {
        do {
            let reportingService = UserReportingService(apiService: self.apiService)
            try await reportingService.unblockUser(
                blockerId: blockerId,
                blockedId: blockedId
            )
            
            await MainActor.run {
                self.friendshipStatus = .none
                self.errorMessage = nil
            }
            
            // Refresh friends cache for consistency
            await AppCache.shared.refreshFriends()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to unblock user: \(error.localizedDescription)"
            }
        }
    }
    
    func checkIfUserBlocked(blockerId: UUID, blockedId: UUID) async -> Bool {
        do {
            let reportingService = UserReportingService(apiService: self.apiService)
            return try await reportingService.isUserBlocked(
                blockerId: blockerId,
                blockedId: blockedId
            )
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to check block status: \(error.localizedDescription)"
            }
            return false
        }
    }
}

// Enum to represent friendship status
enum FriendshipStatus {
    case unknown    // Status not yet determined
    case none       // Not friends
    case friends    // Already friends
    case requestSent // Current user sent request to profile user
    case requestReceived // Profile user sent request to current user
    case themself       // It's the current user's own profile
    case blocked        // User is blocked
}

