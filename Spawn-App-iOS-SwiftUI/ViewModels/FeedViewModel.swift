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
	var userId: UUID

	init(apiService: IAPIService, userId: UUID) {
		self.apiService = apiService
		self.userId = userId
    }

	func fetchAllData() async -> Void {
		await fetchEventsForUser()
		await fetchTagsForUser()
	}

	func fetchEventsForUser() async -> Void {
		// /api/v1/events/feedEvents/{requestingUserId}
		if let url = URL(string: APIService.baseURL + "events/feedEvents/\(userId.uuidString)") {
			do {
				let fetchedEvents: [Event] = try await self.apiService.fetchData(
					from: url, parameters: nil
				)

				// Ensure updating on the main thread
				await MainActor.run {
					self.events = fetchedEvents
				}
			} catch {
				if let statusCode = apiService.errorStatusCode, apiService.errorStatusCode != 404 {
					print("Invalid status code from response: \(statusCode)")
					print(apiService.errorMessage ?? "")
				}
				await MainActor.run {
					self.events = []
				}
			}
		}
	}

	func fetchTagsForUser() async -> Void {
		// /api/v1/friendTags/owner/{ownerId}?full=full
		if let url = URL(string: APIService.baseURL + "friendTags/owner/\(userId.uuidString)") {
			do {
				let fetchedTags: [FriendTag] = try await self.apiService.fetchData(from: url, parameters: ["full": "true"])

				// Ensure updating on the main thread
				await MainActor.run {
					self.tags = fetchedTags
				}
			} catch {
				if let statusCode = apiService.errorStatusCode, apiService.errorStatusCode != 404 {
					print("Invalid status code from response: \(statusCode)")
					print(apiService.errorMessage ?? "")
				}
				await MainActor.run {
					self.tags = []
				}
			}
		}
	}

}
