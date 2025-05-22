//
//  AddFriendsToTagViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-06.
//

import Foundation

class AddFriendsToTagViewModel: ObservableObject {
	@Published var friends: [BaseUserDTO] = []
	@Published var selectedFriends: [BaseUserDTO] = []
	@Published var errorMessage: String? = nil
	@Published var isLoading: Bool = false

	var userId: UUID
	var apiService: IAPIService
	private var appCache: AppCache

	init(userId: UUID, apiService: IAPIService) {
		self.userId = userId
		self.apiService = apiService
		self.appCache = AppCache.shared
	}

	// Fetch all data in parallel
	func fetchAllData(friendTagId: UUID) async {
		await MainActor.run {
			isLoading = true
		}
		
		// Create a task group to run operations in parallel
		await withTaskGroup(of: Void.self) { group in
			group.addTask { await self.fetchFriendsToAddToTag(friendTagId: friendTagId) }
			// Add other fetches here if needed in the future
		}
		
		await MainActor.run {
			isLoading = false
		}
	}

	func fetchFriendsToAddToTag(friendTagId: UUID) async {
		// First check if we have friends in the cache
		if !appCache.friends.isEmpty {
			// Get all tag friends for this tag from the cache
			if let tagFriends = appCache.tagFriends[friendTagId] {
				// Filter cached friends to exclude friends that are already in the tag
				let tagFriendIds = Set(tagFriends.map { $0.id })
				let friendsNotInTag = appCache.friends.filter { !tagFriendIds.contains($0.id) }
				
				// Convert FullFriendUserDTO to BaseUserDTO
				let baseUsers = friendsNotInTag.map { friend -> BaseUserDTO in
					BaseUserDTO.from(friendUser: friend)
				}
				
				await MainActor.run {
					print("Using cached friends: \(baseUsers.count) friends")
					self.friends = baseUsers
					self.errorMessage = nil
					self.objectWillChange.send()
				}
				
				// Return early if we have cache data
				return
			}
		}
		
		// If no cache or missing tag friends data, fetch from API
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
					"Friends data: \(fetchedFriends.map { $0.name ?? "Unknown" })"
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
		
		await MainActor.run {
			isLoading = true
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
                
                // Post a notification that friends were added to a tag
                await MainActor.run {
                    NotificationCenter.default.post(name: .friendsAddedToTag, object: friendTagId)
                    isLoading = false
                    
                    // Update the cached tag friends for this tag
                    if let existingTagFriends = appCache.tagFriends[friendTagId] {
                        // Append selected friends to existing friends
                        let updatedTagFriends = existingTagFriends + selectedFriends
                        appCache.updateTagFriends(friendTagId, updatedTagFriends)
                    } else {
                        // Just add the selected friends if no existing data
                        appCache.updateTagFriends(friendTagId, selectedFriends)
                    }
                }
			} catch {
				print("Error adding friends to tag: \(error.localizedDescription)")
				await MainActor.run {
					print(
						"Error adding friends to tag: \(apiService.errorMessage ?? "")"
					)
                    isLoading = false
				}
			}
		} else {
            await MainActor.run {
                isLoading = false
            }
        }
	}
} 
