//
//  EventCreationViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import Foundation

class EventCreationViewModel: ObservableObject {
	@Published var event: Event
	@Published var creationMessage: String = ""

	private var apiService: IAPIService

	init(apiService: IAPIService, creatingUser: User) {
		self.apiService = apiService
		self.event = Event(id: UUID(), title: "", creator: creatingUser)
	}

	func createEvent() async -> Void {
		if let url = URL(string: APIService.baseURL + "events") {
			do {
				try await self.apiService.sendData(event, to: url)
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
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		return formatter.string(from: date)
	}
}
