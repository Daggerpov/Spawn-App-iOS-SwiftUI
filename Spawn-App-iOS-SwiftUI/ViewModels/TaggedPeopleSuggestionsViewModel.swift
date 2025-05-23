//
//  TaggedPeopleSuggestionsViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-11.
//

import Foundation
import Combine

class TaggedPeopleSuggestionsViewModel: ObservableObject {
    @Published var suggestedFriends: [BaseUserDTO] = []
    @Published var addedFriends: [BaseUserDTO] = []
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    
    private var userId: UUID
    private var tagId: UUID
    private var apiService: IAPIService
    
    init(userId: UUID, tagId: UUID, apiService: IAPIService) {
        self.userId = userId
        self.tagId = tagId
        self.apiService = apiService
    }
    
    // Fetch suggested friends for a tag
    func fetchSuggestedFriends() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Use the existing endpoint for friends not in a tag
        if let url = URL(string: APIService.baseURL + "friendTags/friendsNotAddedToTag/\(tagId)") {
            do {
                let fetchedFriends: [BaseUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
                
                await MainActor.run {
                    self.suggestedFriends = fetchedFriends
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.suggestedFriends = []
                    self.errorMessage = "Error loading suggested friends: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // Fetch already added friends for a tag
    func fetchTagFriends() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Use the existing endpoint for friends in a tag
        if let url = URL(string: APIService.baseURL + "friendTags/\(tagId)/friends") {
            do {
                let fetchedFriends: [BaseUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
                
                await MainActor.run {
                    self.addedFriends = fetchedFriends
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error loading added friends: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // Add a friend to the tag
    func addFriendToTag(_ friend: BaseUserDTO) async {
        await MainActor.run {
            isLoading = true
        }
        
        // Use the existing endpoint for modifying friend tag friends
        if let url = URL(string: APIService.baseURL + "friendTags/\(tagId)") {
            do {
                let parameters = ["friendTagAction": "addFriend", "userId": friend.id.uuidString]
                let _ = try await apiService.sendData(EmptyObject(), to: url, parameters: parameters)

                await MainActor.run {
                    // Add to added friends and remove from suggested
                    if !self.addedFriends.contains(where: { $0.id == friend.id }) {
                        self.addedFriends.append(friend)
                    }
                    self.suggestedFriends.removeAll(where: { $0.id == friend.id })
                    self.isLoading = false
                    
                    // Post notification that friends were added to a tag
                    NotificationCenter.default.post(name: .friendsAddedToTag, object: self.tagId)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error adding friend to tag: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // Remove a friend from the tag
    func removeFriendFromTag(_ friend: BaseUserDTO) async {
        await MainActor.run {
            isLoading = true
        }
        
        // Use the existing endpoint for modifying friend tag friends
        if let url = URL(string: APIService.baseURL + "friendTags/\(tagId)") {
            do {
                let parameters = ["friendTagAction": "removeFriend", "userId": friend.id.uuidString]
				let _ = try await apiService.sendData(EmptyObject(), to: url, parameters: parameters)
                
                await MainActor.run {
                    // Remove from added friends and add to suggested
                    self.addedFriends.removeAll(where: { $0.id == friend.id })
                    if !self.suggestedFriends.contains(where: { $0.id == friend.id }) {
                        self.suggestedFriends.append(friend)
                    }
                    self.isLoading = false
                    
                    // Post notification that friends were modified in a tag
                    NotificationCenter.default.post(name: .friendsAddedToTag, object: self.tagId)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error removing friend from tag: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // Method to fetch all required data in parallel
    func fetchAllData() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Create a task group to run operations in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchSuggestedFriends() }
            group.addTask { await self.fetchTagFriends() }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
} 
