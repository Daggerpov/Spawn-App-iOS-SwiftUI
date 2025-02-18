//
//  EventCreationViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import Foundation

class EventCreationViewModel: ObservableObject {
	// semi-singleton, that can only be reset upon calling `reInitialize()`
	static var shared: EventCreationViewModel = EventCreationViewModel()

	@Published var selectedDate: Date = Date()
	@Published var event: EventCreationDTO
	@Published var creationMessage: String = ""

	@Published var selectedTags: [FriendTag] = []
	@Published var selectedFriends: [FriendUserDTO] = []

	private var apiService: IAPIService

	public static func reInitialize() {
		shared = EventCreationViewModel()
	}

	// Private initializer to enforce singleton pattern
	private init() {
		self.apiService = MockAPIService.isMocking
		? MockAPIService(userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID()) : APIService()

		let defaultStart = Date()
		let defaultEnd = Date().addingTimeInterval(2 * 60 * 60) // 2 hours later
		self.event = EventCreationDTO(
			id: UUID(),
			title: "",
			startTime: defaultStart,
			endTime: defaultEnd,
			location: Location(id: UUID(), name: "", latitude: 0.0, longitude: 0.0),
			creatorUserId: UserAuthViewModel.shared.spawnUser?.id ?? UUID()
		)
	}


	func createEvent() async -> Void {
		// Ensure times are set if not already provided
		if event.startTime == nil {
			event.startTime = combineDateAndTime(selectedDate, time: Date())
		}
		if event.endTime == nil {
			event.endTime = combineDateAndTime(selectedDate, time: Date().addingTimeInterval(2 * 60 * 60))
		}

		// Populate invited user and tag IDs from the selected arrays
		event.invitedFriendUserIds = selectedFriends.map { $0.id }
		event.invitedFriendTagIds = selectedTags.map { $0.id }

		if let url = URL(string: APIService.baseURL + "events") {
			do {
				try await self.apiService.sendData(event, to: url, parameters: nil)
			} catch {
				await MainActor.run {
					creationMessage = "There was an error creating your event. Please try again"
					print(apiService.errorMessage ?? "")
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

	// Helper function to format the date for display
	func formatDate(_ date: Date) -> String {
		let calendar = Calendar.current
		let now = Date()

		// If the date is today, show "today" without time
		if calendar.isDate(date, equalTo: now, toGranularity: .day) {
			return "today"
		}

		// If the date is the current date, return it without time
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		return formatter.string(from: date)
	}
}
