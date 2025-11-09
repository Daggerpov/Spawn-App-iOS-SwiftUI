//
//  FriendRequest.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

/// as defined in the back-end `CreateFriendRequestDTO.java`
struct CreateFriendRequestDTO: Identifiable, Codable, Hashable {
	static func == (lhs: CreateFriendRequestDTO, rhs: CreateFriendRequestDTO) -> Bool {
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

extension CreateFriendRequestDTO {
	static let mockFriendRequests: [CreateFriendRequestDTO] = [
		CreateFriendRequestDTO(
			id: UUID(), senderUserId: UUID(),
			receiverUserId: UUID()),
		CreateFriendRequestDTO(
			id: UUID(),
			senderUserId: UUID(),
			receiverUserId: UUID()
		),
	]
}
