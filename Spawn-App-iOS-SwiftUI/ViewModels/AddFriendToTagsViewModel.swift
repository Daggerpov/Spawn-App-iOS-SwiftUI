//
//  AddFriendToTagsViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-06.
//

import Foundation

class AddFriendToTagsViewModel: ObservableObject {
	@Published var tags: [FriendTagDTO] = []
	@Published var errorMessage: String? = nil
	@Published var isLoading: Bool = false
	@Published var showCreateTagSheet: Bool = false
	
	var userId: UUID
	var apiService: IAPIService
	private var appCache: AppCache
	
	init(userId: UUID, apiService: IAPIService) {
		self.userId = userId
		self.apiService = apiService
		self.appCache = AppCache.shared
	}
	
	func fetchAllData() async {
		await MainActor.run {
			isLoading = true
		}
		
		await fetchUserTags()
		
		await MainActor.run {
			isLoading = false
		}
	}
	
	func fetchUserTags() async {
		// First check if we have tags in the cache
		if !appCache.userTags.isEmpty {
			await MainActor.run {
				self.tags = appCache.userTags
				self.errorMessage = nil
			}
			return
		}
		
		// If no cache data, fetch from API
		if let url = URL(string: APIService.baseURL + "friendTags/user/\(userId)") {
			do {
				let fetchedTags: [FriendTagDTO] = try await self.apiService.fetchData(from: url, parameters: nil)
				
				print("Fetched tags: \(fetchedTags.count) tags")
				
				await MainActor.run {
					self.tags = fetchedTags
					self.errorMessage = nil
					
					// Update the cache
					self.appCache.updateUserTags(fetchedTags)
				}
			} catch {
				print("Error fetching tags: \(error.localizedDescription)")
				await MainActor.run {
					self.tags = []
					self.errorMessage = "Error loading tags: \(error.localizedDescription)"
				}
			}
		}
	}
	
	func addFriendToTag(friendId: UUID, tagId: UUID) async -> Bool {
		if let url = URL(string: APIService.baseURL + "friendTags/addFriendToTag") {
			do {
				let params = ["friendTagId": tagId.uuidString, "friendId": friendId.uuidString]
				_ = try await self.apiService.sendData(
                    EmptyBody(), 
                    to: url, 
                    parameters: params
                )
				
				// Notify that friend was added to tag
				await MainActor.run {
					NotificationCenter.default.post(name: .friendsAddedToTag, object: tagId)
					
					// Update the cache for the tag's friends
					if var cachedTagFriends = appCache.tagFriends[tagId] {
						// Get the friend from the friends cache
						if let friend = appCache.friends.first(where: { $0.id == friendId }) {
							// Add to the cached tag friends
							let baseUser = BaseUserDTO.from(friendUser: friend)

							// Only add if not already in the list
							if !cachedTagFriends.contains(where: { $0.id == friendId }) {
								cachedTagFriends.append(baseUser)
								appCache.updateTagFriends(tagId, cachedTagFriends)
							}
						}
					} else {
						// Fetch tag friends from API if not in cache
						Task {
							await self.fetchAndUpdateTagFriends(tagId: tagId)
						}
					}
				}
				
				return true
			} catch {
				print("Error adding friend to tag: \(error.localizedDescription)")
				return false
			}
		}
		return false
	}
	
	// Helper method to fetch tag friends and update cache
	private func fetchAndUpdateTagFriends(tagId: UUID) async {
		if let url = URL(string: APIService.baseURL + "friendTags/\(tagId)/friends") {
			do {
				let fetchedFriends: [BaseUserDTO] = try await self.apiService.fetchData(from: url, parameters: nil)
				
				await MainActor.run {
					appCache.updateTagFriends(tagId, fetchedFriends)
				}
			} catch {
				print("Error fetching tag friends: \(error.localizedDescription)")
			}
		}
	}
}
