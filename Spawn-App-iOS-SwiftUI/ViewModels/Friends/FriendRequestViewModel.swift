//
//  FriendRequestViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shannon S on 2025-02-07.
//

import Foundation

@Observable
@MainActor
final class FriendRequestViewModel {
	var dataService: DataService
	var userId: UUID
	var friendRequestId: UUID

	var creationMessage: String = ""

	init(userId: UUID, friendRequestId: UUID, dataService: DataService? = nil) {
		self.dataService = dataService ?? DataService.shared
		self.userId = userId
		self.friendRequestId = friendRequestId
	}

	func friendRequestAction(action: FriendRequestAction) async {
		let result: DataResult<EmptyResponse>

		// Use DataService with WriteOperationType
		switch action {
		case .accept:
			result = await dataService.writeWithoutResponse(
				.acceptFriendRequest(requestId: friendRequestId)
			)
		case .decline:
			result = await dataService.writeWithoutResponse(
				.declineFriendRequest(requestId: friendRequestId)
			)
		case .cancel:
			// For cancel, we need a generic delete operation
			let operation = WriteOperation<EmptyRequestBody>.delete(
				endpoint: "friend-requests/\(friendRequestId)",
				body: EmptyRequestBody(),
				cacheInvalidationKeys: ["friendRequests", "sentFriendRequests"]
			)
			result = await dataService.writeWithoutResponse(operation)
		}

		// Handle the result
		switch result {
		case .success:
			print("Successfully processed friend request: \(action.rawValue)")

			// Post notifications to refresh UI immediately
			if action == .accept {
				// Refresh friends list cache
				let _: DataResult<[FullFriendUserDTO]> = await dataService.read(
					.friends(userId: userId), cachePolicy: .apiOnly)
				let _: DataResult<[FetchFriendRequestDTO]> = await dataService.read(
					.friendRequests(userId: userId), cachePolicy: .apiOnly)

				// Notify other views to refresh
				NotificationCenter.default.post(name: .friendsDidChange, object: nil)
			}
			NotificationCenter.default.post(name: .friendRequestsDidChange, object: nil)

		case .failure(let error):
			creationMessage =
				"There was an error \(action == .accept ? "accepting" : action == .cancel ? "canceling" : "declining") the friend request. Please try again"
			print("Error processing friend request: \(error)")
		}
	}
}

enum FriendRequestAction: String {
	case accept = "accept"
	case decline = "reject"
	case cancel = "cancel"
}
