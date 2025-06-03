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
			location: Location(
				id: UUID(), name: "", latitude: 0.0, longitude: 0.0),
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

	func createActivity() async {
		// Validate form before proceeding
		await validateActivityForm()
		guard isFormValid else {
			await MainActor.run {
				creationMessage = "Please fix the errors before creating the activity."
			}
			return
		}
		
		// Ensure times are set if not already provided
		if activity.startTime == nil {
			activity.startTime = combineDateAndTime(selectedDate, time: Date())
		}
		if activity.endTime == nil {
			activity.endTime = combineDateAndTime(
				selectedDate, time: Date().addingTimeInterval(2 * 60 * 60))
		}

		// Populate invited user IDs from the selected array
		activity.invitedFriendUserIds = selectedFriends.map { $0.id }
		
		// Set the selected category
		activity.category = selectedCategory

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

	// Helper function to combine a date and a time into a single Date
	func combineDateAndTime(_ date: Date, time: Date) -> Date {
		let calendar = Calendar.current
		let dateComponents = calendar.dateComponents(
			[.year, .month, .day], from: date)
		let timeComponents = calendar.dateComponents(
			[.hour, .minute], from: time)
		var combinedComponents = DateComponents()
		combinedComponents.year = dateComponents.year
		combinedComponents.month = dateComponents.month
		combinedComponents.day = dateComponents.day
		combinedComponents.hour = timeComponents.hour
		combinedComponents.minute = timeComponents.minute
		return calendar.date(from: combinedComponents) ?? date
	}
} 