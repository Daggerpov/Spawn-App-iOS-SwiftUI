//
//  FeedViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation

class FeedViewModel: ObservableObject {
    @Published var events: [Event] = []
	@Published var tags: [FriendTag] = []

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
				let fetchedEvents: [Event] = try await self.apiService.fetchData(
					from: url,
					parameters: nil
				)

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

	func fetchTagsForUser() async -> Void {
		// TODO DANIEL: change back to "friendTags?ownerId=ownerId" later
		if let url = URL(string: APIService.baseURL + "friendTags") {
			do {
				let fetchedTags: [FriendTag] = try await self.apiService.fetchData(from: url, parameters: nil)

				// Ensure updating on the main thread
				await MainActor.run {
					self.tags = fetchedTags
				}
			} catch {
				await MainActor.run {
					self.tags = []
				}
				print(apiService.errorMessage ?? "")
			}
		}
	}

}
