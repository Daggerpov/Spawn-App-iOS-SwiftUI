//
//  FeedViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation

@MainActor
class FeedViewModel: ObservableObject {
    @Published var events: [Event] = []

	var apiService: IAPIService
	var user: User

	init(apiService: IAPIService, user: User) {
		self.apiService = apiService
		self.user = user
    }

	func fetchEventsForUser() async -> Void {
		// TODO DANIEL: change back to "events/user/\(user.id)" later
		if let url = URL(string: APIService.baseURL + "events") {
			do {
				let fetchedEvents: [Event] = try await self.apiService.fetchData(from: url)

				// Ensure updating on the main thread
				await MainActor.run {
					self.events = fetchedEvents
				}
			} catch {
				await MainActor.run {
					self.events = []
				}
				print(apiService.errorMessage ?? "")
			}
		}
	}

}
