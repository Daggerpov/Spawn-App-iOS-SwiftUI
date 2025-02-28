//
//  FriendRequestDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

/// as defined in the back-end `FetchFriendRequestDTO.java`
struct FetchFriendRequestDTO: Identifiable, Codable, Hashable {
	static func == (lhs: FetchFriendRequestDTO, rhs: FetchFriendRequestDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var senderUser: UserDTO

	init(id: UUID, senderUser: UserDTO) {
		self.id = id
		self.senderUser = senderUser
	}
}

extension FetchFriendRequestDTO {
	static let mockFriendRequests: [FetchFriendRequestDTO] = [
		FetchFriendRequestDTO(
			id: UUID(), senderUser: UserDTO.michael),
		FetchFriendRequestDTO(
			id: UUID(),
			senderUser: UserDTO.shannon
		)
	]
}
