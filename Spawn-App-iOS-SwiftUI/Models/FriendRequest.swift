//
//  FriendRequest.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

/// as defined in the back-end `FullFriendRequestDTO.java`
///
/// except, the ids are straight-up `User` objects here
struct FriendRequest: Identifiable, Codable, Hashable {
	static func == (lhs: FriendRequest, rhs: FriendRequest) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var senderUser: User
	var receiverUser: User

	init(id: UUID, senderUser: User, receiverUser: User) {
		self.id = id
		self.senderUser = senderUser
		self.receiverUser = receiverUser
	}
}

extension FriendRequest {
	static let mockFriendRequests: [FriendRequest] = [
		FriendRequest(
			id: UUID(), senderUser: User.michael,
			receiverUser: User.danielAgapov),
		FriendRequest(
			id: UUID(),
			senderUser: User.shannon,
			receiverUser: User.danielAgapov
		),
	]
}
