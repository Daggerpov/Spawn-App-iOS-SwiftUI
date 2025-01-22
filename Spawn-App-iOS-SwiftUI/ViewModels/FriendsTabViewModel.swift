//
//  FriendsTabViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

class FriendsTabViewModel: ObservableObject {
	@Published var incomingFriendRequests: [FriendRequest] = []
	@Published var recommendedFriends: [User] = []
	@Published var friends: [User] = []

	@Published var friendRequestCreationMessage: String = ""
	@Published var createdFriendRequest: FriendRequest?

	var userId: UUID
	var apiService: IAPIService

	init(userId: UUID, apiService: IAPIService) {
		self.userId = userId
		self.apiService = apiService
	}

	func fetchAllData() async {
		await fetchIncomingFriendRequests()
		await fetchRecommendedFriends()
		await fetchFriends()
	}

	internal func fetchIncomingFriendRequests () async {
		if let url = URL(string: APIService.baseURL + "users/\(userId)/friend-requests") {
			do {
				let fetchedIncomingFriendRequests: [FriendRequest] = try await self.apiService.fetchData(from: url)

				// Ensure updating on the main thread
				await MainActor.run {
					self.incomingFriendRequests = fetchedIncomingFriendRequests
				}
			} catch {
				await MainActor.run {
					self.incomingFriendRequests = []
				}
				print(apiService.errorMessage ?? "")
			}
		}
	}

	internal func fetchRecommendedFriends() async {
		if let url = URL(string: APIService.baseURL + "users/\(userId)/recommended-friends") {
			do {
				let fetchedRecommendedFriends: [User] = try await self.apiService.fetchData(from: url)

				// Ensure updating on the main thread
				await MainActor.run {
					self.recommendedFriends = fetchedRecommendedFriends
				}
			} catch {
				await MainActor.run {
					self.recommendedFriends = []
				}
				print(apiService.errorMessage ?? "")
			}
		}
	}

	internal func fetchFriends() async {
		if let url = URL(string: APIService.baseURL + "users/\(userId)/friends") {
			do {
				let fetchedFriends: [User] = try await self.apiService.fetchData(from: url)

				// Ensure updating on the main thread
				await MainActor.run {
					self.friends = fetchedFriends
				}
			} catch {
				await MainActor.run {
					self.friends = []
				}
				print(apiService.errorMessage ?? "")
			}
		}
	}

	func addFriend(friendUserId: UUID) async {
        let createdFriendRequest = FriendRequestCreationDTO(
			id: UUID(),
			senderUserId: userId,
			receiverUserId: friendUserId
		)
		if let url = URL(string: APIService.baseURL + "users/friend-request") {
			do {
				try await self.apiService.sendData(createdFriendRequest, to: url)
			} catch {
				await MainActor.run {
					friendRequestCreationMessage = "There was an error creating your friend request. Please try again"
					print(apiService.errorMessage ?? "")
				}
			}
		}
	}
}
