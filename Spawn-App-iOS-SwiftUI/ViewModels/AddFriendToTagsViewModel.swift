//
//  AddFriendToTagsViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-06.
//

import Foundation

class AddFriendToTagsViewModel: ObservableObject {
	@Published var tags: [FullFriendTagDTO] = []
	@Published var errorMessage: String? = nil
	@Published var isLoading: Bool = false
	@Published var showCreateTagSheet: Bool = false
	@Published var selectedTags: Set<UUID> = []
	
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
                // Convert FriendTagDTOs to FullFriendTagDTOs by adding friends from cache
                let fullTags = appCache.userTags.map { tag -> FullFriendTagDTO in
                    let friends = appCache.tagFriends[tag.id] ?? []
                    return FullFriendTagDTO(
                        id: tag.id,
                        displayName: tag.displayName,
                        colorHexCode: tag.colorHexCode,
                        friends: friends
                    )
                }
				self.tags = fullTags
				self.errorMessage = nil
			}
			return
		}
		
		// If no cache data, fetch from API
		if let url = URL(string: APIService.baseURL + "friendTags/user/\(userId)") {
			do {
				let fetchedTags: [FriendTagDTO] = try await self.apiService.fetchData(from: url, parameters: nil)
				
				print("Fetched tags: \(fetchedTags.count) tags")

				// Convert to full tags with friends
				var fullTags: [FullFriendTagDTO] = []
				for tag in fetchedTags {
					// Fetch friends for each tag
					let friends = await fetchFriendsForTag(tagId: tag.id)
					let fullTag = FullFriendTagDTO(
						id: tag.id,
						displayName: tag.displayName,
						colorHexCode: tag.colorHexCode,
						friends: friends
					)
					fullTags.append(fullTag)
				}

				let tagsToStore = fullTags
                let fetchedTagsToStore = fetchedTags
				await MainActor.run { [tagsToStore, fetchedTagsToStore] in
					self.tags = tagsToStore
					self.errorMessage = nil
					
					// Update the cache
					self.appCache.updateUserTags(fetchedTagsToStore)
                    
                    // Update tag friends in cache
                    for fullTag in tagsToStore {
                        if let friends = fullTag.friends {
                            self.appCache.updateTagFriends(fullTag.id, friends)
                        }
                    }
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
    
    func fetchTagsToAddToFriend(friendUserId: UUID) async {
        await fetchTagsFriendNotIn(friendUserId: friendUserId)
    }
    
    func fetchTagsFriendNotIn(friendUserId: UUID) async {
        await MainActor.run {
            isLoading = true
        }
        
        // First try to use cache
        if !appCache.userTags.isEmpty {
            // Filter tags to only include ones that don't contain the friend
            let filteredTags = appCache.userTags.filter { tag in
                !(tag.friendUserIds?.contains(friendUserId) ?? false)
            }.map { tag -> FullFriendTagDTO in
                let friends = appCache.tagFriends[tag.id] ?? []
                return FullFriendTagDTO(
                    id: tag.id,
                    displayName: tag.displayName,
                    colorHexCode: tag.colorHexCode,
                    friends: friends
                )
            }
            
            await MainActor.run { [filteredTags] in
                self.tags = filteredTags
                self.isLoading = false
            }
            return
        }
        
        // If not in cache, fetch from API
        if let url = URL(string: APIService.baseURL + "friendTags/addUserToTags/\(userId)?friendUserId=\(friendUserId)") {
            do {
                let fetchedTags: [FriendTagDTO] = try await self.apiService.fetchData(from: url, parameters: nil)
                
                // Convert to full tags with friends
                var fullTags: [FullFriendTagDTO] = []
                for tag in fetchedTags {
                    // Fetch friends for each tag
                    let friends = await fetchFriendsForTag(tagId: tag.id)
                    let fullTag = FullFriendTagDTO(
                        id: tag.id,
                        displayName: tag.displayName,
                        colorHexCode: tag.colorHexCode,
                        friends: friends
                    )
                    fullTags.append(fullTag)
                }
                
                let tagsToStore = fullTags
                await MainActor.run { [tagsToStore] in
                    self.tags = tagsToStore
                    self.errorMessage = nil
                    self.isLoading = false
                }
            } catch {
                print("Error fetching tags friend not in: \(error.localizedDescription)")
                await MainActor.run {
                    self.tags = []
                    self.errorMessage = "Error loading tags: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

	func addTagsToFriend(friendUserId: UUID) async {
        if selectedTags.isEmpty {
            return
        }
        
        // Using the proper endpoint from FriendTagController: "addUserToTags"
        if let url = URL(string: APIService.baseURL + "friendTags/addUserToTags?friendUserId=\(friendUserId)") {
            do {
                // Convert Set<UUID> to Array for the request
                let tagIds = Array(selectedTags)
                
                // Send the tag IDs as the request body
                _ = try await self.apiService.sendData(
                    tagIds,
                    to: url,
                    parameters: nil
                )
                
                // Notify that friend was added to tags
                await MainActor.run {
                    // Post notification for each tag
                    for tagId in selectedTags {
                        NotificationCenter.default.post(name: .friendsAddedToTag, object: tagId)
                        
                        // Update the cache for each tag
                        if var cachedTagFriends = appCache.tagFriends[tagId] {
                            // Get the friend from the friends cache
                            if let friend = appCache.friends.first(where: { $0.id == friendUserId }) {
                                // Add to the cached tag friends
                                let baseUser = BaseUserDTO.from(friendUser: friend)
                                
                                // Only add if not already in the list
                                if !cachedTagFriends.contains(where: { $0.id == friendUserId }) {
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
                }
            } catch {
                print("Error adding friend to tags: \(error.localizedDescription)")
            }
        }
    }
    
    func toggleTagSelection(_ tagId: UUID) {
        if selectedTags.contains(tagId) {
            selectedTags.remove(tagId)
        } else {
            selectedTags.insert(tagId)
        }
    }
    
    func getSelectedTags() -> [FullFriendTagDTO] {
        return tags.filter { selectedTags.contains($0.id) }
    }
	
    // Fetch friends for a specific tag
    private func fetchFriendsForTag(tagId: UUID) async -> [BaseUserDTO] {
        // First check cache
        if let cachedFriends = appCache.tagFriends[tagId] {
            return cachedFriends
        }
        
        // If not in cache, fetch from API
        return await fetchAndUpdateTagFriends(tagId: tagId)
    }
    
	// Helper method to fetch tag friends and update cache
	private func fetchAndUpdateTagFriends(tagId: UUID) async -> [BaseUserDTO] {
		if let url = URL(string: APIService.baseURL + "friendTags/\(tagId)/friends") {
			do {
				let fetchedFriends: [BaseUserDTO] = try await self.apiService.fetchData(from: url, parameters: nil)
				
				await MainActor.run {
					appCache.updateTagFriends(tagId, fetchedFriends)
				}
                
                return fetchedFriends
			} catch {
				print("Error fetching tag friends: \(error.localizedDescription)")
                return []
			}
		}
        return []
	}

    // This function is preserved for compatibility with any existing calls
    // It now uses the correct endpoint from the controller
    func addFriendToTag(friendId: UUID, tagId: UUID) async -> Bool {
        if let url = URL(string: APIService.baseURL + "friendTags/\(tagId)?friendTagAction=addFriend&userId=\(friendId)") {
            do {
                // Using the appropriate endpoint with path parameters and query parameters
                _ = try await self.apiService.sendData(
                    EmptyBody(), 
                    to: url, 
                    parameters: nil
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
}
