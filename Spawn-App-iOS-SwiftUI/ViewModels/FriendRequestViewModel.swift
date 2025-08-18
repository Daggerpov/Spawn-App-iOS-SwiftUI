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

	func friendRequestAction(action: FriendRequestAction) async {
		do {
			// full path: /api/v1/friend-requests/{friendRequestId}
			guard
				let url = URL(
					string: APIService.baseURL
						+ "friend-requests/\(friendRequestId)"
				)
			else { return }

			// make API call:
			if action == .cancel {
				try await self.apiService.deleteData(from: url, parameters: nil, object: Optional<String>.none)
			} else {
				let _: EmptyResponse = try await self.apiService.updateData(
					EmptyRequestBody(), to: url,
					parameters: ["friendRequestAction": action.rawValue])
			}
			print("processed friend request at url: \(url.absoluteString)")
		} catch {
			await MainActor.run {
				creationMessage =
					"There was an error \(action == .accept ? "accepting" : action == .cancel ? "canceling" : "declining") the friend request. Please try again"
			}
		}
	}
}

enum FriendRequestAction: String {
	case accept = "accept"
	case decline = "reject"
	case cancel = "cancel"
}
