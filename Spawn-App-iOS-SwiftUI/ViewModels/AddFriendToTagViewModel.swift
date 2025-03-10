//
//  AddFriendToTagViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-06.
//

import Foundation

class AddFriendToTagViewModel: ObservableObject {
	@Published var friends: [UserDTO] =
		MockAPIService.isMocking ? UserDTO.mockUsers : []
	@Published var selectedFriends: [UserDTO] = []

	var userId: UUID
	var apiService: IAPIService

	init(userId: UUID, apiService: IAPIService) {
		self.userId = userId
		self.apiService = apiService
	}

	internal func fetchFriendsToAddToTag(friendTagId: UUID) async {
		// full path: /api/v1/friendTags/friendsNotAddedToTag/{friendTagId}
		if let url = URL(
			string: APIService.baseURL
				+ "friendTags/friendsNotAddedToTag/\(friendTagId)")
		{
			do {
				let fetchedFriends: [UserDTO] = try await self.apiService
					.fetchData(from: url, parameters: nil)

				// Ensure updating on the main thread
				await MainActor.run {
					self.friends = fetchedFriends
				}
			} catch {
				await MainActor.run {
					self.friends = []
				}
			}
		}
	}

	// Toggle friend selection
	func toggleFriendSelection(_ friend: UserDTO) {
		if selectedFriends.contains(where: { $0.id == friend.id }) {
			selectedFriends.removeAll { $0.id == friend.id }  // Deselect
		} else {
			selectedFriends.append(friend)  // Select
		}
	}

	func addSelectedFriendsToTag(friendTagId: UUID) async {
		if let url = URL(
			string: APIService.baseURL + "friendTags/bulkAddFriendsToTag")
		{
			do {
				_ = try await self.apiService.sendData(
					selectedFriends, to: url,
					parameters: ["friendTagId": friendTagId.uuidString])
			} catch {
				await MainActor.run {
					print(
						"Error adding friends to tag: \(apiService.errorMessage ?? "")"
					)
				}
			}
		}
	}

}
