//
//  FriendsTabViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

class FriendsTabViewModel: ObservableObject {
	@Published var incomingFriendRequests: [FetchFriendRequestDTO] = []
	@Published var recommendedFriends: [UserDTO] = []
	@Published var friends: [FullFriendUserDTO] = []

	@Published var friendRequestCreationMessage: String = ""
	@Published var createdFriendRequest: FetchFriendRequestDTO?

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

	internal func fetchIncomingFriendRequests() async {
		// full path: /api/v1/friend-requests/incoming/{userId}
		if let url = URL(
			string: APIService.baseURL + "friend-requests/incoming/\(userId)")
		{
			do {
				let fetchedIncomingFriendRequests: [FetchFriendRequestDTO] =
					try await self.apiService.fetchData(
						from: url, parameters: nil)

				// Ensure updating on the main thread
				await MainActor.run {
					self.incomingFriendRequests = fetchedIncomingFriendRequests
				}
			} catch {
				if let statusCode = apiService.errorStatusCode,
					apiService.errorStatusCode != 404
				{
					print("Invalid status code from response: \(statusCode)")
					print(apiService.errorMessage ?? "")
				}
				await MainActor.run {
					self.incomingFriendRequests = []
				}
			}
		}
	}

	internal func fetchRecommendedFriends() async {
		if let url = URL(
			string: APIService.baseURL + "users/recommended-friends/\(userId)")
		{
			do {
				let fetchedRecommendedFriends: [UserDTO] =
					try await self.apiService.fetchData(
						from: url, parameters: nil)

				// Ensure updating on the main thread
				await MainActor.run {
					self.recommendedFriends = fetchedRecommendedFriends
				}
			} catch {
				if let statusCode = apiService.errorStatusCode,
					apiService.errorStatusCode != 404
				{
					print("Invalid status code from response: \(statusCode)")
					print(apiService.errorMessage ?? "")
				}
				await MainActor.run {
					self.recommendedFriends = []
				}
			}
		}
	}

	internal func fetchFriends() async {
		if let url = URL(string: APIService.baseURL + "users/friends/\(userId)")
		{
			do {
				let fetchedFriends: [FullFriendUserDTO] = try await self.apiService
					.fetchData(from: url, parameters: nil)

				// Ensure updating on the main thread
				await MainActor.run {
					self.friends = fetchedFriends
				}
			} catch {
				if let statusCode = apiService.errorStatusCode,
					apiService.errorStatusCode != 404
				{
					print("Invalid status code from response: \(statusCode)")
					print(apiService.errorMessage ?? "")
				}
				await MainActor.run {
					self.friends = []
				}
			}
		}
	}

	func addFriend(friendUserId: UUID) async {
		let createdFriendRequest = CreateFriendRequestDTO(
			id: UUID(),
			senderUserId: userId,
			receiverUserId: friendUserId
		)
		// full path: /api/v1/friend-requests
		if let url = URL(string: APIService.baseURL + "friend-requests") {
			do {
				_ = try await self.apiService.sendData(
					createdFriendRequest, to: url, parameters: nil)
			} catch {
				await MainActor.run {
					friendRequestCreationMessage =
						"There was an error creating your friend request. Please try again"
					print(apiService.errorMessage ?? "")
				}
			}
		}
		await fetchAllData()
	}
}
