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
	@Published var deletionMessage: String = ""

	var apiService: IAPIService
	var userId: UUID

	var newTag: FriendTagCreationDTO

	init(apiService: IAPIService, userId: UUID) {
		self.apiService = apiService
		self.userId = userId
		self.newTag = FriendTagCreationDTO(
			id: UUID(),
			displayName: "",
			colorHexCode: "",
			ownerUserId: userId
		)
    }

	func fetchTags() async -> Void {
		if let url = URL(string: APIService.baseURL + "friendTags/owner/\(userId)") {
			do {
				let fetchedTags: [FriendTag] = try await self.apiService.fetchData(from: url,
																				   parameters: ["full": "true"]
				)

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

	func upsertTag(id: UUID? = nil, displayName: String, colorHexCode: String, upsertAction: UpsertActionType) async -> Void {
		if displayName.isEmpty {
			creationMessage = "Please enter a display name"
			return
		}

		newTag = FriendTagCreationDTO(
			id: id ?? UUID(),
			displayName: displayName,
			colorHexCode: colorHexCode,
			ownerUserId: user.id
		)

		if let url = URL(string: APIService.baseURL + "friendTags") {
			do {
				switch upsertAction {
					case .create:
						try await self.apiService.sendData(newTag, to: url, parameters: nil)
					case .update:
						try await self.apiService.updateData(newTag, to: url)
				}
			} catch {
				await MainActor.run {
					creationMessage = "There was an error creating your tag. Please try again"
					print(apiService.errorMessage ?? "")
				}
			}
		}

		// re-fetching tags after creation, since it's now
		// been created and should be added to this group
		await fetchTags()
	}
}
