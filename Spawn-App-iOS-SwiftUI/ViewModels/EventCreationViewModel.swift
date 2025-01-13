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
}
