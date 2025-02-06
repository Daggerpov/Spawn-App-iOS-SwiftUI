//
//  EventCreationViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import Foundation

class EventCreationViewModel: ObservableObject {
	static let shared: EventCreationViewModel = EventCreationViewModel()
	
	@Published var event: EventCreationDTO
	@Published var creationMessage: String = ""

	@Published var selectedTags: [FriendTag] = []
	@Published var selectedFriends: [FriendUserDTO] = []

	private var apiService: IAPIService

	// Private initializer to enforce singleton pattern
	private init() {
		self.apiService = MockAPIService.isMocking
		? MockAPIService(userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID()) : APIService()

		// Initialize the event with the logged-in user's `userId`, and a random `id`
		self.event = EventCreationDTO(
			id: UUID(),
			title: "",
			creatorUserId: UserAuthViewModel.shared.spawnUser?.id ?? UUID()
		)
	}

	func createEvent() async -> Void {
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
