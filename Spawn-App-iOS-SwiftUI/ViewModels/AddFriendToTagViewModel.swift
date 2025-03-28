//
//  AddFriendToTagViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-06.
//

import Foundation

class AddFriendToTagViewModel: ObservableObject {
	@Published var friends: [BaseUserDTO] = []
	@Published var selectedFriends: [BaseUserDTO] = []
	@Published var errorMessage: String? = nil

	var userId: UUID
	var apiService: IAPIService

	init(userId: UUID, apiService: IAPIService) {
		self.userId = userId
		self.apiService = apiService
	}

	func fetchFriendsToAddToTag(friendTagId: UUID) async {
		// full path: /api/v1/friendTags/friendsNotAddedToTag/{friendTagId}
		if let url = URL(
			string: APIService.baseURL
				+ "friendTags/friendsNotAddedToTag/\(friendTagId)")
		{
			do {
				let fetchedFriends: [BaseUserDTO] = try await self.apiService
					.fetchData(from: url, parameters: nil)

				print("Fetched friends to add to tag: \(fetchedFriends.count) friends")
				print(
					"Friends data: \(fetchedFriends.map { $0.firstName ?? "?" + " " + ($0.lastName ?? "?")})"
				)
				
				// Ensure updating on the main thread
				await MainActor.run {
					print("Setting friends array with \(fetchedFriends.count) friends")
					self.friends = fetchedFriends
					print("After setting, friends count: \(self.friends.count)")
					self.errorMessage = nil
					self.objectWillChange.send()  // Explicitly notify observers
				}
			} catch {
				print("Error fetching friends not added to tag: \(error.localizedDescription)")
				await MainActor.run {
					self.friends = []
					self.errorMessage = "Error loading friends: \(error.localizedDescription)"
					self.objectWillChange.send()  // Explicitly notify observers
				}
			}
		}
	}

	// Toggle friend selection
	func toggleFriendSelection(_ friend: BaseUserDTO) {
		if selectedFriends.contains(where: { $0.id == friend.id }) {
			selectedFriends.removeAll { $0.id == friend.id }  // Deselect
		} else {
			selectedFriends.append(friend)  // Select
		}
	}

	func addSelectedFriendsToTag(friendTagId: UUID) async {
		if selectedFriends.isEmpty {
			print("No friends selected to add")
			return
		}
		
		if let url = URL(
			string: APIService.baseURL + "friendTags/bulkAddFriendsToTag")
		{
			do {
				print("Adding \(selectedFriends.count) friends to tag \(friendTagId)")
				_ = try await self.apiService.sendData(
					selectedFriends, to: url,
					parameters: ["friendTagId": friendTagId.uuidString])
				
				print("Successfully added friends to tag")
			} catch {
				print("Error adding friends to tag: \(error.localizedDescription)")
				await MainActor.run {
					print(
						"Error adding friends to tag: \(apiService.errorMessage ?? "")"
					)
				}
			}
		}
	}

}
