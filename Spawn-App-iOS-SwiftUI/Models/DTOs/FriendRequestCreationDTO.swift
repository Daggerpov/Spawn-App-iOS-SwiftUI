//
//  FriendRequestCreationDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-22.
//

import Foundation

/// as defined in the back-end `FriendRequestDTO.java`
struct FriendRequestCreationDTO: Identifiable, Codable, Hashable {
	static func == (lhs: FriendRequestCreationDTO, rhs: FriendRequestCreationDTO) -> Bool {
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

extension FriendRequestCreationDTO {
	static let mockFriendRequestCreationDTOs: [FriendRequestCreationDTO] = [
		FriendRequestCreationDTO(
			id: UUID(), senderUserId: User.michael.id,
			receiverUserId: User.danielAgapov.id),
		FriendRequestCreationDTO(
			id: UUID(),
			senderUserId: User.shannon.id,
			receiverUserId: User.danielAgapov.id
		),
	]
}
