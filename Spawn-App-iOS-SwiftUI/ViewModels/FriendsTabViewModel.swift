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
	@Published var friends: [FriendUserDTO] = []

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
				let fetchedIncomingFriendRequests: [FriendRequest] = try await self.apiService.fetchData(from: url, parameters: nil)

				// Ensure updating on the main thread
				await MainActor.run {
					self.incomingFriendRequests = fetchedIncomingFriendRequests
				}
			} catch {
				if let statusCode = apiService.errorStatusCode, apiService.errorStatusCode != 404 {
					print("Invalid status code from response: \(statusCode)")
					print(apiService.errorMessage ?? "")
				}
				await MainActor.run {
					self.incomingFriendRequests = []
				}
			}
		}
		await fetchAllData()
	}

	internal func fetchRecommendedFriends() async {
		if let url = URL(string: APIService.baseURL + "users/\(userId)/recommended-friends") {
			do {
				let fetchedRecommendedFriends: [User] = try await self.apiService.fetchData(from: url, parameters: nil)

				// Ensure updating on the main thread
				await MainActor.run {
					self.recommendedFriends = fetchedRecommendedFriends
				}
			} catch {
				if let statusCode = apiService.errorStatusCode, apiService.errorStatusCode != 404 {
					print("Invalid status code from response: \(statusCode)")
					print(apiService.errorMessage ?? "")
				}
				await MainActor.run {
					self.recommendedFriends = []
				}
			}
		}
		await fetchAllData()
	}

	internal func fetchFriends() async {
		if let url = URL(string: APIService.baseURL + "users/\(userId)/friends") {
			do {
				let fetchedFriends: [FriendUserDTO] = try await self.apiService.fetchData(from: url, parameters: nil)

				// Ensure updating on the main thread
				await MainActor.run {
					self.friends = fetchedFriends
				}
			} catch {
				if let statusCode = apiService.errorStatusCode, apiService.errorStatusCode != 404 {
					print("Invalid status code from response: \(statusCode)")
					print(apiService.errorMessage ?? "")
				}
				await MainActor.run {
					self.friends = []
				}
			}
		}
		await fetchAllData()
	}

	func addFriend(friendUserId: UUID) async {
        let createdFriendRequest = FriendRequestCreationDTO(
			id: UUID(),
			senderUserId: userId,
			receiverUserId: friendUserId
		)
		if let url = URL(string: APIService.baseURL + "users/friend-request") {
			do {
				try await self.apiService.sendData(createdFriendRequest, to: url, parameters: nil)
			} catch {
				await MainActor.run {
					friendRequestCreationMessage = "There was an error creating your friend request. Please try again"
					print(apiService.errorMessage ?? "")
				}
			}
		}
		await fetchAllData()
	}
}
