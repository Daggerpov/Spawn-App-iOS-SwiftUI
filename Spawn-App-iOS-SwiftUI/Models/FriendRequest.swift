//
//  FriendRequest.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

/// as defined in the back-end `FriendRequestDTO.java`
struct FriendRequest: Identifiable, Codable, Hashable {
	static func == (lhs: FriendRequest, rhs: FriendRequest) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var senderUserId: UUID
	var receiverUserId: UUID

	init (id: UUID, senderUserId: UUID, receiverUserId: UUID) {
		self.id = id
		self.senderUserId = senderUserId
		self.receiverUserId = receiverUserId
	}
}
