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

	func fetchTags() async {
		if let url = URL(
			string: APIService.baseURL + "friendTags/owner/\(userId)")
		{
			do {
				let fetchedTags: [FriendTag] = try await self.apiService
					.fetchData(
						from: url,
						parameters: ["full": "true"]
					)

				// Ensure updating on the main thread
				await MainActor.run {
					self.tags = fetchedTags
				}
			} catch {
				if let statusCode = apiService.errorStatusCode,
					apiService.errorStatusCode != 404
				{
					print("Invalid status code from response: \(statusCode)")
					print(apiService.errorMessage ?? "")
				}

				await MainActor.run {
					self.tags = []
				}
			}
		}
	}

	func upsertTag(
		id: UUID? = nil, displayName: String, colorHexCode: String,
		upsertAction: UpsertActionType
	) async {
		if displayName.isEmpty {
			creationMessage = "Please enter a display name"
			return
		}

		newTag = FriendTagCreationDTO(
			id: id ?? UUID(),
			displayName: displayName,
			colorHexCode: colorHexCode,
			ownerUserId: userId
		)

		do {
			switch upsertAction {
			case .create:
				guard let url = URL(string: APIService.baseURL + "friendTags")
				else { return }
				try await self.apiService.sendData(
					newTag, to: url, parameters: nil)
			case .update:
				guard
					let url = URL(
						string: APIService.baseURL + "friendTags/\(newTag.id)")
				else { return }
				let update: FriendTagCreationDTO = try await self.apiService
					.updateData(newTag, to: url)
			}
		} catch {
			await MainActor.run {
				creationMessage =
					"There was an error creating your tag. Please try again"
				print(apiService.errorMessage ?? "")
			}
		}

		// re-fetching tags after creation, since it's now
		// been created and should be added to this group
		await fetchTags()
	}

	func deleteTag(id: UUID) async {
		if let url = URL(string: APIService.baseURL + "friendTags/\(id)") {
			do {
				try await self.apiService.deleteData(from: url)
				await MainActor.run {
					self.tags.removeAll { $0.id == id }  // Remove the tag from the local list
				}
			} catch {
				await MainActor.run {
					deletionMessage =
						"There was an error deleting the tag. Please try again."
					print(apiService.errorMessage ?? "")
				}
			}
		}
		await fetchTags()
	}
}
