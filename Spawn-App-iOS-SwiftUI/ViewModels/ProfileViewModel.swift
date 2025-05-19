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
}
