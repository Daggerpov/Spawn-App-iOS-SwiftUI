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
	
	private var apiService: IAPIService
	
	public static func reInitialize() {
		shared = ActivityCreationViewModel()
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
			creatorUserId: UserAuthViewModel.shared.spawnUser?.id ?? UUID()
		)
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
		
		activity.title = type.rawValue
		activity.icon = type.icon
		activity.category = type.toActivityCategory()
	}
	
	func setLocation(_ location: Location) {
		selectedLocation = location
		activity.location = location
	}

	func createActivity() async {
		// Update activity with final details
		updateActivityType()
		updateActivityDuration()
		
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
