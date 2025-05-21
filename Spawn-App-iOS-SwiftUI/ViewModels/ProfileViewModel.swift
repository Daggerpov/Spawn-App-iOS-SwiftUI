import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var userStats: UserStatsDTO?
    @Published var userInterests: [String] = []
    @Published var userSocialMedia: UserSocialMediaDTO?
    @Published var isLoadingStats: Bool = false
    @Published var isLoadingInterests: Bool = false
    @Published var isLoadingSocialMedia: Bool = false
    @Published var showDrawer: Bool = false
    @Published var errorMessage: String?
    @Published var calendarActivities: [[CalendarActivityDTO?]] = Array(
        repeating: Array(repeating: nil, count: 7),
        count: 5
    )
    @Published var isLoadingCalendar: Bool = false
    @Published var allCalendarActivities: [CalendarActivityDTO] = []
    @Published var selectedEvent: FullFeedEventDTO?
    @Published var isLoadingEvent: Bool = false
    
    // New properties for friendship status
    @Published var friendshipStatus: FriendshipStatus = .unknown
    @Published var isLoadingFriendshipStatus: Bool = false
    @Published var pendingFriendRequestId: UUID?
    @Published var userEvents: [FullFeedEventDTO] = []
    @Published var isLoadingUserEvents: Bool = false
    
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
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/stats")!
            let stats: UserStatsDTO = try await self.apiService.fetchData(
                from: url,
                parameters: nil
            )
            
            await MainActor.run {
                self.userStats = stats
                self.isLoadingStats = false
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
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/interests")!
            let interests: [String] = try await self.apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                self.userInterests = interests
                self.isLoadingInterests = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load user interests: \(error.localizedDescription)"
                self.isLoadingInterests = false
            }
        }
    }
    
    func addUserInterest(userId: UUID, interest: String) async {
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/interests")!
            _ = try await self.apiService.sendData(interest, to: url, parameters: nil)
            
            // Refresh interests after adding
            await fetchUserInterests(userId: userId)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to add interest: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchUserSocialMedia(userId: UUID) async {
        await MainActor.run { self.isLoadingSocialMedia = true }
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/social-media")!
            let socialMedia: UserSocialMediaDTO = try await self.apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                self.userSocialMedia = socialMedia
                self.isLoadingSocialMedia = false
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
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update social media: \(error.localizedDescription)"
            }
        }
    }
    
    func loadAllProfileData(userId: UUID) async {
        await fetchUserStats(userId: userId)
        await fetchUserInterests(userId: userId)
        await fetchUserSocialMedia(userId: userId)
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
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load calendar: \(error.localizedDescription)"
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
        
        // Place first activity of each day in the grid
        for (day, dayActivities) in activitiesByDay {
            if !dayActivities.isEmpty {
                let position = day + firstDayOffset - 1
                if position >= 0 && position < 35 {
                    let row = position / 7
                    let col = position % 7
                    grid[row][col] = dayActivities.first
                }
            }
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
    
    // Interest management methods
    func removeUserInterest(userId: UUID, interest: String) async {
        await MainActor.run { self.isLoadingInterests = true }
        
        do {
            let url = URL(string: APIService.baseURL + "users/\(userId)/interests/\(interest)")!
            let _ = try await apiService.deleteData(
                from: url,
                parameters: nil,
                object: EmptyObject()
            )
            
            // Update local state immediately after successful deletion
            await MainActor.run {
                self.userInterests.removeAll { $0 == interest }
                self.isLoadingInterests = false
            }
            
            // Refresh interests from server to ensure consistency
            await fetchUserInterests(userId: userId)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to remove interest: \(error.localizedDescription)"
                self.isLoadingInterests = false
            }
        }
    }
    
    // MARK: - Event Management
    
    func fetchEventDetails(eventId: UUID) async -> FullFeedEventDTO? {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            await MainActor.run {
                self.errorMessage = "User ID not available"
            }
            return nil
        }
        
        await MainActor.run { self.isLoadingEvent = true }
        
        do {
            let url = URL(string: APIService.baseURL + "events/\(eventId)")!
            let parameters = ["requestingUserId": userId.uuidString]
            
            let event: FullFeedEventDTO = try await apiService.fetchData(
                from: url,
                parameters: parameters
            )
            
            await MainActor.run {
                self.selectedEvent = event
                self.isLoadingEvent = false
            }
            
            return event
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load event: \(error.localizedDescription)"
                self.isLoadingEvent = false
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
            let isFriendResponse: IsFriendResponseDTO = try await self.apiService.fetchData(from: url, parameters: nil)
            
            if isFriendResponse.isFriend {
				print("user is friends with this user whose profile they've clicked on.")
                await MainActor.run {
                    self.friendshipStatus = .friends
                    self.isLoadingFriendshipStatus = false
                }
                return
            }
            
            // If not friends, check for pending friend requests
            let pendingRequestUrl = URL(string: APIService.baseURL + "friend-requests/pending-between/\(currentUserId)/\(profileUserId)")!
            let pendingRequest: PendingFriendRequestDTO? = try await self.apiService.fetchData(from: pendingRequestUrl, parameters: nil)
            
            await MainActor.run {
                if let pendingRequest = pendingRequest {
                    if pendingRequest.senderId == currentUserId {
                        self.friendshipStatus = .requestSent
                    } else {
                        self.friendshipStatus = .requestReceived
                        self.pendingFriendRequestId = pendingRequest.id
                    }
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
    
    // MARK: - User Events
    
    func fetchUserUpcomingEvents(userId: UUID) async {
        await MainActor.run { self.isLoadingUserEvents = true }
        
        do {
            let url = URL(string: APIService.baseURL + "events/user/\(userId)/upcoming")!
            let events: [FullFeedEventDTO] = try await self.apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                self.userEvents = events
                self.isLoadingUserEvents = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load user events: \(error.localizedDescription)"
                self.userEvents = []
                self.isLoadingUserEvents = false
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
    
    func reportUser(reporterId: UUID, reportedId: UUID, reason: String) async {
        do {
            let url = URL(string: APIService.baseURL + "user-reports")!
            let reportDTO = UserReportCreationDTO(
                id: UUID(),
                reporterUserId: reporterId,
                reportedUserId: reportedId,
                reason: reason
            )
            
            // Discard the return value
            _ = try await self.apiService.sendData(
                reportDTO,
                to: url,
                parameters: nil
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
    
    func blockUser(blockerId: UUID, blockedId: UUID, reason: String) async {
        do {
            let url = URL(string: APIService.baseURL + "blocked-users/block")!
            let blockDTO = BlockedUserCreationDTO(
                id: UUID(),
                blockerId: blockerId,
                blockedId: blockedId,
                reason: reason
            )
            
            // Discard the return value
            _ = try await self.apiService.sendData(
                blockDTO,
                to: url,
                parameters: nil
            )
            
            await MainActor.run {
                self.friendshipStatus = .blocked
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to block user: \(error.localizedDescription)"
            }
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

// DTOs for friend status checking
struct IsFriendResponseDTO: Codable {
    let isFriend: Bool
}

struct PendingFriendRequestDTO: Codable, Identifiable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
}

// DTOs for user reporting and blocking
struct UserReportCreationDTO: Codable {
    let id: UUID
    let reporterUserId: UUID
    let reportedUserId: UUID
    let reason: String
}

struct BlockedUserCreationDTO: Codable {
    let id: UUID
    let blockerId: UUID
    let blockedId: UUID
    let reason: String
}

