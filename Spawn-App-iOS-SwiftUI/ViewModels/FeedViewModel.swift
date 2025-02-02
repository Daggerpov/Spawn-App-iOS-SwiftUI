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
//		/api/v1/events/invitedEvents/{userId}?full=full
		//  full path: /api/v1/events/invitedEvents/{userId}?full=full
		if let url = URL(string: APIService.baseURL + "events/invitedEvents/\(user.id.uuidString)") {
			do {
				let fetchedEvents: [Event] = try await self.apiService.fetchData(
					from: url,
					parameters: ["full":"true"]
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
		// /api/v1/friendTags/owner/{ownerId}?full=full
		if let url = URL(string: APIService.baseURL + "friendTags/owner/\(user.id.uuidString)") {
			do {
				let fetchedTags: [FriendTag] = try await self.apiService.fetchData(from: url, parameters: ["full": "true"])

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
