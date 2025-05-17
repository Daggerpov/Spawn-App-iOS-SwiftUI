//
//  AddFriendToTagViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-06.
//

import Foundation

class AddFriendToTagViewModel: ObservableObject {
	@Published var tags: [FriendTagDTO] = []
	@Published var errorMessage: String? = nil
	@Published var isLoading: Bool = false
	@Published var showCreateTagSheet: Bool = false
	
	var userId: UUID
	var apiService: IAPIService
	
	init(userId: UUID, apiService: IAPIService) {
		self.userId = userId
		self.apiService = apiService
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
		if let url = URL(string: APIService.baseURL + "friendTags/user/\(userId)") {
			do {
				let fetchedTags: [FriendTagDTO] = try await self.apiService.fetchData(from: url, parameters: nil)
				
				print("Fetched tags: \(fetchedTags.count) tags")
				
				await MainActor.run {
					self.tags = fetchedTags
					self.errorMessage = nil
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
					NotificationCenter.default.post(name: .friendsAddedToTag, object: nil)
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
