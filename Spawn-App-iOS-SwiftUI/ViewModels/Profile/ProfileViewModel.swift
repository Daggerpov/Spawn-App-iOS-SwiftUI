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
        // Check if user is still authenticated before making API call
        guard UserAuthViewModel.shared.spawnUser != nil, UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot fetch user stats: User is not logged in")
            await MainActor.run {
                self.isLoadingStats = false
            }
            return
        }
        
        // Check cache first - only show loading if we need to fetch from API
        if let cachedStats = AppCache.shared.profileStats[userId] {
            await MainActor.run {
                self.userStats = cachedStats
            }
            print("✅ Using cached profile stats for user \(userId)")
            return
        }
        
        // No cached data - show loading and fetch from API
        await MainActor.run { self.isLoadingStats = true }
        
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
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
                self.isLoadingStats = false
            }
        }
    }
    
    func fetchUserInterests(userId: UUID) async {
        // Check cache first - only show loading if we need to fetch from API
        if let cachedInterests = AppCache.shared.profileInterests[userId] {
            await MainActor.run {
                self.userInterests = cachedInterests
            }
            print("✅ Using cached profile interests for user \(userId)")
            return
        }
        
        // No cached data - show loading and fetch from API
        await MainActor.run { self.isLoadingInterests = true }
        
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
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
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
            
            // Update local state with fresh data from cache to ensure consistency
            await MainActor.run {
                if let cachedInterests = AppCache.shared.profileInterests[userId] {
                    self.userInterests = cachedInterests
                }
            }
            
            return true
        } catch {
            // Revert local state if API call fails
            await MainActor.run {
                self.userInterests.removeAll { $0 == interest }
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
            }
            return false
        }
    }
    
    func fetchUserSocialMedia(userId: UUID) async {
        // Check cache first - only show loading if we need to fetch from API
        if let cachedSocialMedia = AppCache.shared.profileSocialMedia[userId] {
            await MainActor.run {
                self.userSocialMedia = cachedSocialMedia
            }
            print("✅ Using cached social media for user \(userId)")
            return
        }
        
        // No cached data - show loading and fetch from API
        await MainActor.run { self.isLoadingSocialMedia = true }
        
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
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
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
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
            }
        }
    }
    
    func fetchUserProfileInfo(userId: UUID) async {
        // Check if user is still authenticated before making API call
        guard UserAuthViewModel.shared.spawnUser != nil, UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot fetch profile info: User is not logged in")
            await MainActor.run {
                self.isLoadingProfileInfo = false
            }
            return
        }
        
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
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
                self.isLoadingProfileInfo = false
            }
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
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
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
            print("❌ Calendar: No user ID available")
            await MainActor.run {
                self.isLoadingCalendar = false
                self.errorMessage = "User ID not available"
            }
            return
        }
        
        print("📡 Calendar: Fetching activities for user \(userId)")
        print("📡 Calendar: API Mode: \(MockAPIService.isMocking ? "MOCK" : "REAL")")
        print("📡 Calendar: Base URL: \(APIService.baseURL)")
        
        // Check authentication status
        if !MockAPIService.isMocking {
            let hasAccessToken = KeychainService.shared.load(key: "accessToken") != nil
            let hasRefreshToken = KeychainService.shared.load(key: "refreshToken") != nil
            let isLoggedIn = UserAuthViewModel.shared.isLoggedIn
            print("🔐 Calendar: Authentication status - Access token: \(hasAccessToken ? "✅" : "❌"), Refresh token: \(hasRefreshToken ? "✅" : "❌"), Logged in: \(isLoggedIn ? "✅" : "❌")")
            
            if !hasAccessToken && !hasRefreshToken {
                print("❌ Calendar: No authentication tokens found - user may need to log in")
                await MainActor.run {
                    self.errorMessage = "Authentication required - please log in again"
                    self.allCalendarActivities = []
                    self.isLoadingCalendar = false
                }
                return
            }
        }
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/calendar")!
            print("📡 Calendar: Making request to: \(url.absoluteString)")
            
            let activities: [CalendarActivityDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            print("✅ Calendar: Successfully fetched \(activities.count) activities")
            if !activities.isEmpty {
                print("📅 Calendar: Sample activity dates:")
                for activity in activities.prefix(3) {
                    print("   - \(activity.date): \(activity.title ?? "No title")")
                }
            }
            
            await MainActor.run {
                self.allCalendarActivities = activities
                self.isLoadingCalendar = false
                
                // Pre-assign colors for calendar activities
                let activityIds = activities.compactMap { $0.activityId }
                ActivityColorService.shared.assignColorsForActivities(activityIds)
            }
        } catch {
            print("❌ Calendar: Error fetching activities")
            print("❌ Calendar: Error details: \(error)")
            if let apiError = error as? APIError {
                print("❌ Calendar: API Error type: \(apiError)")
                switch apiError {
                case .invalidStatusCode(let statusCode):
                    print("❌ Calendar: HTTP Status Code: \(statusCode)")
                    if statusCode == 401 {
                        print("❌ Calendar: Authentication failed - user may need to log in again")
                    } else if statusCode == 404 {
                        print("❌ Calendar: Endpoint not found - check API URL")
                    }
                case .failedHTTPRequest(let description):
                    print("❌ Calendar: HTTP Request failed: \(description)")
                default:
                    break
                }
            }
            
            await MainActor.run {
                let errorMsg = ErrorFormattingService.shared.formatError(error)
                self.errorMessage = errorMsg
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
        } catch let error as APIError {
            print("❌ ProfileViewModel: Error fetching friend's all calendar activities: \(ErrorFormattingService.shared.formatAPIError(error))")
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
                self.allCalendarActivities = []
                self.isLoadingCalendar = false
            }
        } catch {
            print("❌ ProfileViewModel: Error fetching friend's all calendar activities: \(ErrorFormattingService.shared.formatError(error))")
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
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
                    print("  \(index + 1). \(activity.date) - \(activity.icon ?? "No icon") - ID: \(activity.activityId?.uuidString ?? "No ID")")
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
        } catch let error as APIError {
            print("❌ ProfileViewModel: Error fetching friend's calendar activities: \(ErrorFormattingService.shared.formatAPIError(error))")
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
                self.calendarActivities = Array(
                    repeating: Array(repeating: nil, count: 7),
                    count: 5
                )
                self.allCalendarActivities = []
                self.isLoadingCalendar = false
            }
        } catch {
            print("❌ ProfileViewModel: Error fetching friend's calendar activities: \(ErrorFormattingService.shared.formatError(error))")
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
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
                print("📅 ProfileViewModel: Excluding activity '\(activity.title ?? "No title")' - wrong month/year (\(activityMonth)/\(activityYear))")
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
                    newCalendarActivitiesByDay[row][col] = dayActivities // Store all activities for this day
                    print("📅 ProfileViewModel: Placed \(dayActivities.count) activities at grid position [\(row)][\(col)] for day \(day)")
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
        // Store original state for potential rollback
        let originalInterests = userInterests
        
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
            
            try await apiService.deleteData(
                from: url,
                parameters: nil,
                object: nil as EmptyRequestBody?
            )
            
            // Update cache after successful API call
            await AppCache.shared.refreshProfileInterests(userId)
            
            await MainActor.run {
                objectWillChange.send()
            }
        } catch let error as APIError {
            print("❌ Failed to remove interest '\(interest)': \(ErrorFormattingService.shared.formatAPIError(error))")
            
            // Revert the optimistic update since the API call failed
            await MainActor.run {
                self.userInterests = originalInterests
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
            }
        } catch {
            print("❌ Failed to remove interest '\(interest)': \(ErrorFormattingService.shared.formatError(error))")
            
            // Revert the optimistic update since the API call failed
            await MainActor.run {
                self.userInterests = originalInterests
                
                // Provide specific error message based on the error type
                if (error as NSError).localizedDescription.contains("404") {
                    self.errorMessage = "Interest '\(interest)' was not found in your profile. Your interests have been refreshed."
                    // Force refresh from server to sync cache
                    Task {
                        await self.fetchUserInterests(userId: userId)
                    }
                } else {
                    self.errorMessage = "Failed to remove interest: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Method for edit profile flow - doesn't revert local state on error
    func removeUserInterestForEdit(userId: UUID, interest: String) async {
        do {
            // URL encode the interest name to handle spaces and special characters
            guard let encodedInterest = interest.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                print("❌ Failed to encode interest name: \(interest)")
                return
            }
            
            let url = URL(string: APIService.baseURL + "users/\(userId)/interests/\(encodedInterest)")!
            
            try await apiService.deleteData(
                from: url,
                parameters: nil,
                object: nil as EmptyRequestBody?
            )
            
            print("✅ Successfully removed interest: \(interest)")
            
        } catch {
            let nsError = error as NSError
            
            // Treat 404 as success - the interest is already gone
            if nsError.localizedDescription.contains("404") {
                print("✅ Interest '\(interest)' was already removed (404 - treating as success)")
            } else {
                print("❌ Failed to remove interest '\(interest)': \(error.localizedDescription)")
                // For other errors, we could show a warning but still keep the local state
                // since the user explicitly wanted to remove it
            }
        }
        
        // Update cache after attempting to remove
        await AppCache.shared.refreshProfileInterests(userId)
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
        } catch let error as APIError {
            print("❌ ProfileViewModel: Error fetching activity details: \(ErrorFormattingService.shared.formatAPIError(error))")
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
                self.isLoadingActivity = false
            }
        } catch {
            print("❌ ProfileViewModel: Error fetching activity details: \(ErrorFormattingService.shared.formatError(error))")
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
                self.isLoadingActivity = false
            }
            return nil
        }
		return nil
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
            
            // If not friends, check for pending friend requests in parallel
            let incomingRequestsUrl = URL(string: APIService.baseURL + "friend-requests/incoming/\(currentUserId)")!
            let profileUserIncomingUrl = URL(string: APIService.baseURL + "friend-requests/incoming/\(profileUserId)")!
            
            // Fetch both incoming request lists in parallel for faster loading
            async let incomingRequests = self.apiService.fetchData(from: incomingRequestsUrl, parameters: nil) as [FetchFriendRequestDTO]
            async let profileUserIncomingRequests = self.apiService.fetchData(from: profileUserIncomingUrl, parameters: nil) as [FetchFriendRequestDTO]
            
            // Wait for both requests to complete
            let (currentUserRequests, profileUserRequests) = try await (incomingRequests, profileUserIncomingRequests)
            
            // Check if any incoming request is from the profile user
            let requestFromProfileUser = currentUserRequests.first { $0.senderUser.id == profileUserId }
            
            if let requestFromProfileUser = requestFromProfileUser {
                await MainActor.run {
                    let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                    self.friendshipStatus = .requestReceived
                    self.pendingFriendRequestId = (requestFromProfileUser.id == zeroUUID) ? nil : requestFromProfileUser.id
                    self.isLoadingFriendshipStatus = false
                }
                return
            }
            
            // Check if any incoming request to profile user is from current user
            let requestToProfileUser = profileUserRequests.first { $0.senderUser.id == currentUserId }
            
            await MainActor.run {
                if requestToProfileUser != nil {
                    self.friendshipStatus = .requestSent
                } else {
                    self.friendshipStatus = .none
                }
                self.isLoadingFriendshipStatus = false
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
                self.friendshipStatus = .unknown
                self.isLoadingFriendshipStatus = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
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
                
                // Remove the user from recommended friends cache so they disappear from the friends tab
                let currentRecommendedFriends = AppCache.shared.getCurrentUserRecommendedFriends()
                let updatedRecommendedFriends = currentRecommendedFriends.filter { $0.id != toUserId }
                AppCache.shared.updateRecommendedFriendsForUser(updatedRecommendedFriends, userId: fromUserId)
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
            }
        }
    }
    
    func acceptFriendRequest(requestId: UUID) async {
        // IMMEDIATELY update UI state to provide instant feedback
        await MainActor.run {
            self.friendshipStatus = .friends
            self.pendingFriendRequestId = nil
        }
        
        print("[PROFILE] accepted friend request id=\(requestId) -> status=friends")
        NotificationCenter.default.post(name: .friendRequestsDidChange, object: nil)
        
        do {
            let url = URL(string: APIService.baseURL + "friend-requests/\(requestId)")!
            let _: EmptyResponse = try await self.apiService.updateData(
                EmptyRequestBody(),
                to: url,
                parameters: ["friendRequestAction": "accept"]
            )
            
            // Refresh caches so other views update immediately
            Task {
                await AppCache.shared.refreshFriends()
                await AppCache.shared.forceRefreshAllFriendRequests()
                NotificationCenter.default.post(name: .friendsDidChange, object: nil)
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
                // Revert the optimistic update on failure
                self.friendshipStatus = .requestReceived
                self.pendingFriendRequestId = requestId
            }
        } catch {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
                // Revert the optimistic update on failure
                self.friendshipStatus = .requestReceived
                self.pendingFriendRequestId = requestId
            }
        }
    }
    
    func declineFriendRequest(requestId: UUID) async {
        // IMMEDIATELY update UI state to provide instant feedback
        await MainActor.run {
            self.friendshipStatus = .none
            self.pendingFriendRequestId = nil
        }
        
        NotificationCenter.default.post(name: .friendRequestsDidChange, object: nil)
        
        do {
            let url = URL(string: APIService.baseURL + "friend-requests/\(requestId)")!
            let _: EmptyResponse = try await self.apiService.updateData(
                EmptyRequestBody(),
                to: url,
                parameters: ["friendRequestAction": "reject"]
            )
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
                // Revert the optimistic update on failure
                self.friendshipStatus = .requestReceived
                self.pendingFriendRequestId = requestId
            }
        } catch {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
                // Revert the optimistic update on failure
                self.friendshipStatus = .requestReceived
                self.pendingFriendRequestId = requestId
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
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
                self.userActivities = []
                self.isLoadingUserActivities = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
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
        
        // Check cache first - only show loading if we need to fetch from API
        if let cachedActivities = AppCache.shared.profileActivities[profileUserId] {
            print("✅ Using cached profile activities: \(cachedActivities.count)")
            await MainActor.run {
                self.profileActivities = cachedActivities
            }
            return
        }
        
        // No cached data - show loading and fetch from API
        await MainActor.run { self.isLoadingUserActivities = true }
        
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
        } catch let error as APIError {
            print("❌ ProfileViewModel: Error fetching profile activities: \(ErrorFormattingService.shared.formatAPIError(error))")
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
                self.profileActivities = []
                self.isLoadingUserActivities = false
            }
        } catch {
            print("❌ ProfileViewModel: Error fetching profile activities: \(ErrorFormattingService.shared.formatError(error))")
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
                self.profileActivities = []
                self.isLoadingUserActivities = false
            }
        }
    }
    
    // MARK: - Friend Management
    
    func removeFriend(currentUserId: UUID, profileUserId: UUID) async {
        do {
            let url = URL(string: APIService.baseURL + "api/v1/users/friends/\(currentUserId)/\(profileUserId)")!
            
            // Use DELETE request to remove friendship
            _ = try await self.apiService.deleteData(
                from: url,
                parameters: nil,
                object: Optional<String>.none
            )
            
            await MainActor.run {
                self.friendshipStatus = .none
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
            }
        }
    }
    
    func reportUser(reporterUserId: UUID, reportedUserId: UUID, reportType: ReportType, description: String) async {
        do {
            let reportingService = ReportingService(apiService: self.apiService)
            try await reportingService.reportUser(
                reporterUserId: reporterUserId,
                reportedUserId: reportedUserId,
                reportType: reportType,
                description: description
            )
            
            await MainActor.run {
                self.errorMessage = nil
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
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
            let reportingService = ReportingService(apiService: self.apiService)
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
            
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
            }
        }
    }
    
    func unblockUser(blockerId: UUID, blockedId: UUID) async {
        do {
            let reportingService = ReportingService(apiService: self.apiService)
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
            
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
            }
        }
    }
    
    func checkIfUserBlocked(blockerId: UUID, blockedId: UUID) async -> Bool {
        do {
            let reportingService = ReportingService(apiService: self.apiService)
            return try await reportingService.isUserBlocked(
                blockerId: blockerId,
                blockedId: blockedId
            )
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatAPIError(error)
            }
            return false
        } catch {
            await MainActor.run {
                self.errorMessage = ErrorFormattingService.shared.formatError(error)
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

