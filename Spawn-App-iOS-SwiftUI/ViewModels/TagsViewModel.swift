//
//  TagsViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-13.
//

import Foundation

class TagsViewModel: ObservableObject {
	@Published var tags: [FriendTag] = []
	@Published var creationMessage: String = ""

	var apiService: IAPIService
	var user: User

	var newTag: FriendTag

	init(apiService: IAPIService, user: User) {
		self.apiService = apiService
		self.user = user
		self.newTag = FriendTag(
			id: UUID(),
			displayName: "",
			colorHexCode: "",
			ownerId: user.id,
			friends: nil
		)
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

	func createTag() async -> Void {
		if let url = URL(string: APIService.baseURL + "friendTags") {
			do {
				try await self.apiService.sendData(newTag, to: url)
			} catch {
				await MainActor.run {
					creationMessage = "There was an error creating your tag. Please try again"
					print(apiService.errorMessage ?? "")
				}
			}
		}
	}
}
