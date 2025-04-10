//
//  TagsViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-13.
//

import Foundation

class TagsViewModel: ObservableObject {
	@Published var tags: [FullFriendTagDTO] = []
	@Published var creationMessage: String = ""
	@Published var deletionMessage: String = ""
	@Published var friendRemovalMessage: String = ""
	@Published var isLoading: Bool = false

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

	// Optimized method to fetch all required data in parallel
	func fetchAllData() async {
		await MainActor.run {
			isLoading = true
		}
		
		// Create a task group to run operations in parallel
		await withTaskGroup(of: Void.self) { group in
			group.addTask { await self.fetchTags() }
			// Add other related fetches here if needed in the future
		}
		
		await MainActor.run {
			isLoading = false
		}
	}

	func fetchTags() async {
		if let url = URL(
			string: APIService.baseURL + "friendTags/owner/\(userId)")
		{
			do {
				let fetchedTags: [FullFriendTagDTO] = try await self.apiService
					.fetchData(
						from: url,
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
			}
		}
	}

	func upsertTag(
		id: UUID? = nil, displayName: String, colorHexCode: String,
		upsertAction: UpsertActionType
	) async {
		if displayName.isEmpty {
			await MainActor.run {
				creationMessage = "Please enter a display name"
			}
			return
		}

		newTag = FriendTagCreationDTO(
			id: id ?? UUID(),
			displayName: displayName,
			colorHexCode: colorHexCode,
			ownerUserId: userId
		)

		var tagCreatedSuccessfully = false
		
		do {
			switch upsertAction {
			case .create:
				guard let url = URL(string: APIService.baseURL + "friendTags")
				else { return }
				_ = try await self.apiService.sendData(
					newTag, to: url, parameters: nil)
				tagCreatedSuccessfully = true
			case .update:
				guard
					let url = URL(
						string: APIService.baseURL + "friendTags/\(newTag.id)")
				else { return }
					let _: FriendTagCreationDTO = try await self.apiService
					.updateData(newTag, to: url, parameters: nil)
				tagCreatedSuccessfully = true
			}
		} catch {
			await MainActor.run {
				creationMessage =
					"There was an error creating your tag. Please try again"
			}
		}

		// Only fetch tags if the operation was successful
		if tagCreatedSuccessfully {
			// re-fetching tags after creation, since it's now
			// been created and should be added to this group
			await fetchAllData()
		}
	}

	func deleteTag(id: UUID) async {
		var tagDeletedSuccessfully = false
		
		if let url = URL(string: APIService.baseURL + "friendTags/\(id)") {
			do {
				try await self.apiService.deleteData(from: url)
				await MainActor.run {
					self.tags.removeAll { $0.id == id }  // Remove the tag from the local list
				}
				tagDeletedSuccessfully = true
			} catch {
				await MainActor.run {
					deletionMessage =
						"There was an error deleting the tag. Please try again."
				}
			}
		}
		
		// Only re-fetch if successfully deleted
		if tagDeletedSuccessfully {
			await fetchAllData()
		}
	}

	func removeFriendFromFriendTag(friendUserId: UUID, friendTagId: UUID) async {
		var removalSuccessful = false
		
		if let url = URL(
			string: APIService.baseURL + "friendTags/\(friendTagId)")
		{
			do {
				_ = try await self.apiService.sendData(
					EmptyBody(),
					to: url,
					parameters: [
						"friendTagAction": "removeFriend",
						"userId": friendUserId.uuidString,
					])
				removalSuccessful = true
			} catch {
				await MainActor.run {
					friendRemovalMessage =
						"There was an error removing your friend from the friend tag. Please try again."
				}
			}
		}
		
		// Only re-fetch if successfully removed
		if removalSuccessful {
			await fetchAllData()
		}
	}
}
