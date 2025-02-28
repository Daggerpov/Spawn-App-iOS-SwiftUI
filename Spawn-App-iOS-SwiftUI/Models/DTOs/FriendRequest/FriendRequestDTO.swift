//
//  FriendRequest.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

/// as defined in the back-end `FriendRequestDTO.java`
struct FriendRequestDTO: Identifiable, Codable, Hashable {
	static func == (lhs: FriendRequestDTO, rhs: FriendRequestDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var senderUserId: UUID
	var receiverUserId: UUID

	init(id: UUID, senderUserId: UUID, receiverUserId: UUID) {
		self.id = id
		self.senderUserId = senderUserId
		self.receiverUserId = receiverUserId
	}
}

extension FriendRequestDTO {
	static let mockFriendRequests: [FriendRequestDTO] = [
		FriendRequestDTO(
			id: UUID(), senderUserId: UUID(),
			receiverUserId: UUID()),
		FriendRequestDTO(
			id: UUID(),
			senderUserId: UUID(),
			receiverUserId: UUID()
		),
	]
}
