//
//  TagsTabViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-13.
//


import Foundation

@MainActor
class TagsTabViewModel: ObservableObject {
	@Published var tags: [FriendTag] = []

	var apiService: IAPIService
	var user: User

	init(apiService: IAPIService, user: User) {
		self.apiService = apiService
		self.user = user
    }

	func fetchTagsForUser() async -> Void {
		// TODO DANIEL: change back to "friendTags?ownerId=ownerId" later
		if let url = URL(string: APIService.baseURL + "friendTags") {
			do {
				let fetchedTags: [FriendTag] = try await self.apiService.fetchData(from: url)

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
