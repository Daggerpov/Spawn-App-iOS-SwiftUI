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
	var senderUser: UUID
	var receiverUser: UUID

	init(id: UUID, senderUser: UUID, receiverUser: UUID) {
		self.id = id
		self.senderUser = senderUser
		self.receiverUser = receiverUser
	}
}

extension FriendRequestDTO {
	static let mockFriendRequests: [FriendRequestDTO] = [
		FriendRequestDTO(
			id: UUID(), senderUser: UUID.michael,
			receiverUser: UUID.danielAgapov),
		FriendRequestDTO(
			id: UUID(),
			senderUser: UUID.shannon,
			receiverUser: UUID.danielAgapov
		),
	]
}
