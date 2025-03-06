//
//  FeedViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation

class FeedViewModel: ObservableObject {
	@Published var events: [FullFeedEventDTO] = []
	@Published var tags: [FullFriendTagDTO] = []
	@Published var activeTag: FullFriendTagDTO?

	var apiService: IAPIService
	var userId: UUID

	init(apiService: IAPIService, userId: UUID) {
		self.apiService = apiService
		self.userId = userId
		self._activeTag = Published(initialValue: tags.first)  // this will automatically null-check
	}

	func fetchAllData() async {
		await fetchEventsForUser()
		await fetchTagsForUser()
	}

	func fetchEventsForUser() async {
		// Declare `setUrl` as an optional URL
		var setUrl: URL?

		if let unwrappedActiveTag = activeTag, !unwrappedActiveTag.isEveryone {
			// Full path: /api/v1/events/friendTag/{friendTagFilterId}
			setUrl = URL(
				string: APIService.baseURL
					+ "events/friendTag/\(unwrappedActiveTag.id)")
		} else {
			// Path: /api/v1/events/feedEvents/{requestingUserId}
			setUrl = URL(
				string: APIService.baseURL + "events/feedEvents/\(userId)")
		}

		// Safely unwrap `setUrl` using `guard let`
		guard let url = setUrl else {
			print("Failed to construct URL")
			return
		}

		do {
			let fetchedEvents: [FullFeedEventDTO] = try await self.apiService.fetchData(
				from: url, parameters: nil
			)

			// Ensure updating on the main thread
			await MainActor.run {
				self.events = fetchedEvents
			}
		} catch {
			await MainActor.run {
				self.events = []
			}
		}
	}

	func fetchTagsForUser() async {
		// /api/v1/friendTags/owner/{ownerId}?full=full
		if let url = URL(
			string: APIService.baseURL + "friendTags/owner/\(userId)"
		) {
			do {
				let fetchedTags: [FullFriendTagDTO] = try await self.apiService
					.fetchData(from: url, parameters: ["full": "true"])

				// Ensure updating on the main thread
				await MainActor.run {
					self.tags = fetchedTags
					self.activeTag = fetchedTags.first
				}
			} catch {
				await MainActor.run {
					self.tags = []
				}
			}
		}
	}

}
