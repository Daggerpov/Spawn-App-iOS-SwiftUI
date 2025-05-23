//
//  EventCreationViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import Foundation
import Combine


class EventCreationViewModel: ObservableObject {
	// semi-singleton, that can only be reset upon calling `reInitialize()`
	static var shared: EventCreationViewModel = EventCreationViewModel()

	@Published var selectedDate: Date = Date()
	@Published var event: EventCreationDTO
	@Published var creationMessage: String = ""

	@Published var selectedTags: [FullFriendTagDTO] = []
	@Published var selectedFriends: [FullFriendUserDTO] = []
	@Published var selectedCategory: EventCategory = .general
	
	// Validation properties
	@Published var isTitleValid: Bool = true
	@Published var isInvitesValid: Bool = true
	@Published var isLocationValid: Bool = true
	@Published var isFormValid: Bool = false
	
	private var apiService: IAPIService
	
	public static func reInitialize() {
		shared = EventCreationViewModel()
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
		self.event = EventCreationDTO(
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
	func validateEventForm() async {
        // Check title
        let trimmedTitle = event.title?.trimmingCharacters(in: .whitespaces) ?? ""
        await MainActor.run {
            isTitleValid = !trimmedTitle.isEmpty
            // Check if at least one friend or tag is invited
            isInvitesValid = !selectedFriends.isEmpty || !selectedTags.isEmpty
            // Check if location is valid
            isLocationValid = event.location != nil && 
                             !event.location!.name.trimmingCharacters(in: .whitespaces).isEmpty && 
                             (event.location!.latitude != 0 || event.location!.longitude != 0)
            
            // Update overall form validity
            isFormValid = isTitleValid && isInvitesValid && isLocationValid
        }
	}

	func createEvent() async {
		// Validate form before proceeding
		await validateEventForm()
		guard isFormValid else {
			await MainActor.run {
				creationMessage = "Please fix the errors before creating the event."
			}
			return
		}
		
		// Ensure times are set if not already provided
		if event.startTime == nil {
			event.startTime = combineDateAndTime(selectedDate, time: Date())
		}
		if event.endTime == nil {
			event.endTime = combineDateAndTime(
				selectedDate, time: Date().addingTimeInterval(2 * 60 * 60))
		}

		// Populate invited user and tag IDs from the selected arrays
		event.invitedFriendUserIds = selectedFriends.map { $0.id }
		event.invitedFriendTagIds = selectedTags.map { $0.id }
		
		// Set the selected category
		event.category = selectedCategory

		if let url = URL(string: APIService.baseURL + "events") {
			do {
				_ = try await self.apiService.sendData(
					event, to: url, parameters: nil)
                
                // Post notification to trigger reload of events in FeedViewModel
                await MainActor.run {
                    NotificationCenter.default.post(name: .eventCreated, object: nil)
                }
			} catch {
				await MainActor.run {
					creationMessage =
						"There was an error creating your event. Please try again"
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
