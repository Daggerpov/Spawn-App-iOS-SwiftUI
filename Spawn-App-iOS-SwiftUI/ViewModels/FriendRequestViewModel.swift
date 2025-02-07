//
//  FriendRequestViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shannon S on 2025-02-07.
//

import Foundation

class FriendRequestViewModel: ObservableObject {
	var apiService: IAPIService
	var userId: UUID
	var friendRequestId: UUID

	@Published var creationMessage: String = ""

	init(apiService: IAPIService, userId: UUID, friendRequestId: UUID) {
		self.apiService = apiService
		self.userId = userId
		self.friendRequestId = friendRequestId
	}

	enum FriendRequestAction {
		case accept, decline
	}

	func friendRequestAction(action: FriendRequestAction) async {
		// determine which URL to hit with a PUT request:
		switch action {
		case .accept:
			// full path: /api/v1/users/{userId}/friend-requests/{friendRequestId}/accept
			guard
				let url = URL(
					string: APIService.baseURL
						+ "users/\(userId)/friend-requests/\(friendRequestId)/accept"
				)
			else { return }
		case .decline:
			// full path: /api/v1/users/{userId}/friend-requests/{friendRequestId}/decline
			guard
				let url = URL(
					string: APIService.baseURL
						+ "users/\(userId)/friend-requests/\(friendRequestId)/decline"
				)
			else { return }
		}

		// make API call:
		do {
			let _: EmptyResponse = try await self.apiService.updateData(
				EmptyRequestBody(), to: url)
			print("accepted friend request at url: \(url.absoluteString)")
		} catch {
			await MainActor.run {
				creationMessage =
					"There was an error \(action == .accept ? "accepting" : "declining") the friend request. Please try again"
				print(apiService.errorMessage ?? "")
			}
		}
	}
}

// since the PUT requests don't need any `@RequestBody` in the back-end
struct EmptyRequestBody: Codable {}
struct EmptyResponse: Codable {}
