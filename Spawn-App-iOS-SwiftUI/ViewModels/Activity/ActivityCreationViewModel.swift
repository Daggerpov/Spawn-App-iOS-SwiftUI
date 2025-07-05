//
//  ActivityCreationViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import Foundation
import Combine


class ActivityCreationViewModel: ObservableObject {
	// semi-singleton, that can only be reset upon calling `reInitialize()`
	static var shared: ActivityCreationViewModel = ActivityCreationViewModel()

	@Published var selectedDate: Date = Date()
	@Published var activity: ActivityCreationDTO
	@Published var creationMessage: String = ""
	@Published var selectedType: ActivityType?
	@Published var selectedDuration: ActivityDuration = .indefinite
	@Published var selectedLocation: Location?

	@Published var selectedFriends: [FullFriendUserDTO] = []
	@Published var selectedCategory: ActivityCategory = .general
	
	// Validation properties
	@Published var isTitleValid: Bool = true
	@Published var isInvitesValid: Bool = true
	@Published var isLocationValid: Bool = true
	@Published var isFormValid: Bool = false
	
	// Loading state
	@Published var isCreatingActivity: Bool = false
	
	private var apiService: IAPIService
	
	public static func reInitialize() {
		shared.resetToDefaults()
	}
	
	// Method to pre-select an activity type (e.g., when coming from feed view)
	public static func initializeWithSelectedType(_ activityType: ActivityType?) {
		// Instead of creating a new instance, reset the existing one and set the type
		shared.resetToDefaults()
		shared.selectedType = activityType
	}
	
	// Helper method to reset the current instance to defaults
	private func resetToDefaults() {
		
		// Reset all properties to their default values
		selectedDate = Date()
		creationMessage = ""
		selectedType = nil
		selectedDuration = .indefinite
		selectedLocation = nil
		selectedFriends = []
		selectedCategory = .general
		isTitleValid = true
		isInvitesValid = true
		isLocationValid = true
		isFormValid = false
		isCreatingActivity = false
		
		// Reset the activity DTO
		let defaultStart = Date()
		let defaultEnd = Date().addingTimeInterval(2 * 60 * 60)  // 2 hours later
		activity = ActivityCreationDTO(
			id: UUID(),
			title: "",
			startTime: defaultStart,
			endTime: defaultEnd,
			location: nil,
			icon: "⭐️",
			category: .general,
			creatorUserId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
			invitedFriendUserIds: []
		)
		
		// Reload friends
		loadAllFriendsAsSelected()
	}
	
	// Force reset method for debugging
	public static func forceReset() {
		shared.selectedType = nil
	}

	// Private initializer to enforce singleton pattern
	private init() {
		self.apiService =
			MockAPIService.isMocking
			? MockAPIService(
				userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID())
			: APIService()

		let defaultStart = Date()
		let defaultEnd = Date().addingTimeInterval(2 * 60 * 60)  // 2 hours later
		self.activity = ActivityCreationDTO(
			id: UUID(),
			title: "",
			startTime: defaultStart,
			endTime: defaultEnd,
			location: nil,
			icon: "⭐️",
			category: .general,
			creatorUserId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
			invitedFriendUserIds: []
		)
		
		// Ensure selectedType starts as nil by default (no auto-selection)
		self.selectedType = nil
		
		// Automatically populate friends when initializing
		loadAllFriendsAsSelected()
	}
	
	// Load all friends and automatically select them for invitation
	private func loadAllFriendsAsSelected() {
		// Check if we have cached friends
		if !AppCache.shared.friends.isEmpty {
			selectedFriends = AppCache.shared.friends
		} else {
			// If no cached friends, fetch them
			Task {
				await fetchAndSelectAllFriends()
			}
		}
	}
	
	// Fetch all friends from API and select them
	private func fetchAndSelectAllFriends() async {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
		
		if let url = URL(string: APIService.baseURL + "users/friends/\(userId)") {
			do {
				let fetchedFriends: [FullFriendUserDTO] = try await self.apiService.fetchData(from: url, parameters: nil)
				
				await MainActor.run {
					self.selectedFriends = fetchedFriends
					// Update the app cache as well
					AppCache.shared.updateFriends(fetchedFriends)
				}
			} catch {
				print("Error fetching friends for auto-invite: \(error.localizedDescription)")
			}
		}
	}
	
	// Helper function to format the date for display
	func formatDate(_ date: Date) -> String {
		let calendar = Calendar.current
		let now = Date()

		// If the date is today, show "today" without time
		if calendar.isDate(date, equalTo: now, toGranularity: .day) {
			return "Today"
		}
		
		// If the date is tomorrow, show "tomorrow"
		if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, equalTo: tomorrow, toGranularity: .day) {
			return "Tomorrow"
		}

		// Otherwise, return the formatted date
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		return formatter.string(from: date)
	}

	// Validates all form fields and returns if the form is valid
	func validateActivityForm() async {
        // Check title
        let trimmedTitle = activity.title?.trimmingCharacters(in: .whitespaces) ?? ""
        await MainActor.run {
            isTitleValid = !trimmedTitle.isEmpty
            // Check if at least one friend is invited
            isInvitesValid = !selectedFriends.isEmpty
            // Check if location is valid
            isLocationValid = activity.location != nil && 
                             !activity.location!.name.trimmingCharacters(in: .whitespaces).isEmpty && 
                             (activity.location!.latitude != 0 || activity.location!.longitude != 0)
            
            // Update overall form validity
            isFormValid = isTitleValid && isInvitesValid && isLocationValid
        }
	}

	func updateActivityDuration() {
		let startTime = selectedDate
		let endTime: Date
		
		switch selectedDuration {
		case .indefinite:
			endTime = Calendar.current.date(byAdding: .hour, value: 24, to: startTime) ?? startTime
		case .twoHours:
			endTime = Calendar.current.date(byAdding: .hour, value: 2, to: startTime) ?? startTime
		case .oneHour:
			endTime = Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
		case .thirtyMinutes:
			endTime = Calendar.current.date(byAdding: .minute, value: 30, to: startTime) ?? startTime
		}
		
		activity.startTime = startTime
		activity.endTime = endTime
	}
	
	func updateActivityType() {
		guard let type = selectedType else { return }
		
		// Don't overwrite the user's custom title with the activity type name
		// Only set icon and category based on the selected type
		activity.icon = type.icon
		activity.category = type.toActivityCategory()
	}
	
	func setLocation(_ location: Location) {
		selectedLocation = location
		activity.location = location
	}

	func createActivity() async {
		// Set loading state to true
		await MainActor.run {
			isCreatingActivity = true
		}
		
		// Update activity with final details
		updateActivityType()
		updateActivityDuration()
		
		// Populate the invited friend user IDs from selected friends
		activity.invitedFriendUserIds = selectedFriends.map { $0.id }
		
		if let url = URL(string: APIService.baseURL + "activities") {
			do {
				_ = try await self.apiService.sendData(
					activity, to: url, parameters: nil)
                
                // Post notification to trigger reload of activities in FeedViewModel
                await MainActor.run {
                    NotificationCenter.default.post(name: .activityCreated, object: nil)
                }
			} catch {
				await MainActor.run {
					creationMessage =
						"There was an error creating your activity. Please try again"
				}
			}
		}
		
		// Set loading state to false when done
		await MainActor.run {
			isCreatingActivity = false
		}
	}
}

// MARK: - Helper Extensions

extension ActivityType {
	func toActivityCategory() -> ActivityCategory {
		switch self {
		case .foodAndDrink:
			return .foodAndDrink
		case .active:
			return .active
		case .grind:
			return .grind
		case .chill:
			return .chill
		case .general:
			return .general
		}
	}
} 
