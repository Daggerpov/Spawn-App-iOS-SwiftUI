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
    
    private let apiService: IAPIService
    
    init(apiService: IAPIService = MockAPIService.isMocking ? MockAPIService() : APIService()) {
        self.apiService = apiService
    }
    
    func fetchUserStats(userId: UUID) async {
        await MainActor.run {
            self.isLoadingStats = true
        }
        
        if let url = URL(string: APIService.baseURL + "users/\(userId)/stats") {
            do {
                let stats: UserStatsDTO = try await self.apiService.fetchData(from: url, parameters: nil)
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
    }
    
    func fetchUserInterests(userId: UUID) async {
        await MainActor.run {
            self.isLoadingInterests = true
        }
        
        if let url = URL(string: APIService.baseURL + "users/\(userId)/interests") {
            do {
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
    }
    
    func addUserInterest(userId: UUID, interest: String) async {
        if let url = URL(string: APIService.baseURL + "users/\(userId)/interests") {
            do {
                let _ = try await self.apiService.sendData(
                    interest,
                    to: url,
                    parameters: nil
                )
                // Refresh interests after adding
                await fetchUserInterests(userId: userId)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to add interest: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchUserSocialMedia(userId: UUID) async {
        await MainActor.run {
            self.isLoadingSocialMedia = true
        }
        
        if let url = URL(string: APIService.baseURL + "users/\(userId)/social-media") {
            do {
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
    }
    
    func updateSocialMedia(userId: UUID, whatsappLink: String?, instagramLink: String?) async {
        if let url = URL(string: APIService.baseURL + "users/\(userId)/social-media") {
            do {
                let updateDTO = UpdateUserSocialMediaDTO(
                    whatsappNumber: whatsappLink,
                    instagramUsername: instagramLink
                )
                
                print("updateDTO: \(updateDTO)")
                
                // Use the existing updateData method correctly
                // Make sure to provide the correct type parameters
                let updatedSocialMedia: UserSocialMediaDTO = try await self.apiService.updateData(
                    updateDTO,
                    to: url,
                    parameters: nil
                )
                
                await MainActor.run {
                    self.userSocialMedia = updatedSocialMedia
                    print("Social media updated successfully: \(updatedSocialMedia)")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update social media: \(error.localizedDescription)"
                    print("Social media update error: \(error)")
                }
            }
        }
    }
    
    func loadAllProfileData(userId: UUID) async {
        await fetchUserStats(userId: userId)
        await fetchUserInterests(userId: userId)
        await fetchUserSocialMedia(userId: userId)
    }
    
    func fetchCalendarActivities(month: Int, year: Int) async {
        await MainActor.run {
            self.isLoadingCalendar = true
        }
        
        // Get the user ID
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            await MainActor.run {
                self.isLoadingCalendar = false
                self.errorMessage = "User ID not available"
            }
            return
        }
        
        // Construct the base URL without query parameters
        guard let url = URL(string: APIService.baseURL + "users/\(userId)/calendar") else {
            await MainActor.run {
                self.isLoadingCalendar = false
                self.errorMessage = "Failed to construct URL for calendar activities"
            }
            return
        }
        
        // Create parameters dictionary
        let parameters = [
            "month": String(month),
            "year": String(year),
        ]
        
        do {
            // Fetch calendar activities from API using parameters
            let activities: [CalendarActivityDTO] = try await apiService.fetchData(
                from: url, parameters: parameters
            )
            
            // Convert to grid format
            let grid = convertToCalendarGrid(activities: activities, month: month, year: year)
            
            // Update UI on main thread
            await MainActor.run {
                self.calendarActivities = grid
                self.isLoadingCalendar = false
            }
        } catch {
            // Handle error and provide fallback
            await MainActor.run {
                self.errorMessage = "Failed to load calendar: \(error.localizedDescription)"
                self.calendarActivities = generateMockCalendarData(month: month, year: year)
                self.isLoadingCalendar = false
            }
        }
    }
    
    private func convertToCalendarGrid(activities: [CalendarActivityDTO], month: Int, year: Int) -> [[CalendarActivityDTO?]] {
        var grid = Array(
            repeating: Array(repeating: nil as CalendarActivityDTO?, count: 7),
            count: 5
        )
        
        let firstDayOffset = firstDayOfMonth(month: month, year: year)
        
        for activity in activities {
            let day = extractDay(from: activity.date)
            let position = day + firstDayOffset - 1
            if position >= 0 && position < 35 {
                let row = position / 7
                let col = position % 7
                grid[row][col] = activity
            }
        }
        
        return grid
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
    
    private func generateMockCalendarData(month: Int, year: Int) -> [[CalendarActivityDTO?]] {
        var activities = Array(
            repeating: Array(repeating: nil as CalendarActivityDTO?, count: 7),
            count: 5
        )
        
        let activityTypes = ["music", "sports", "food", "travel", "gaming", "outdoors"]
        
        // Generate some random activities
        for row in 0..<5 {
            for col in 0..<7 {
                if row > 0 && Bool.random() && Bool.random() {
                    let day = (row * 7) + col + 1
                    if day <= daysInMonth(month: month, year: year) {
                        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
                        activities[row][col] = CalendarActivityDTO(
                            id: UUID(),
                            title: "Activity \(day)",
                            date: date,
                            activityType: activityTypes.randomElement() ?? "other"
                        )
                    }
                }
            }
        }
        
        return activities
    }
    
    private func daysInMonth(month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        
        if let date = calendar.date(from: components),
           let range = calendar.range(of: .day, in: .month, for: date) {
            return range.count
        }
        return 30 // Default fallback
    }
    
    // Interest management methods
    
    func removeUserInterest(userId: UUID, interest: String) async {
        // Add loading state for better UX
        await MainActor.run {
            self.isLoadingInterests = true
        }
        
        if let url = URL(string: APIService.baseURL + "users/\(userId)/interests/\(interest)") {
            do {
                let _ = try await apiService.deleteData(from: url, parameters: nil, object: EmptyObject())
                // Refresh interests after removing
                await fetchUserInterests(userId: userId)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to remove interest: \(error.localizedDescription)"
                    self.isLoadingInterests = false
                }
            }
        }
    }
} 
