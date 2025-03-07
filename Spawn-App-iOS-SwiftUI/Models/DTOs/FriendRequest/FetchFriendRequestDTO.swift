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
	var senderUser: BaseUserDTO

	init(id: UUID, senderUser: BaseUserDTO) {
		self.id = id
		self.senderUser = senderUser
	}
}

extension FetchFriendRequestDTO {
	static let mockFriendRequests: [FetchFriendRequestDTO] = [
		FetchFriendRequestDTO(
			id: UUID(), senderUser: BaseUserDTO.danielAgapov),
		FetchFriendRequestDTO(
			id: UUID(),
			senderUser: BaseUserDTO.danielLee
		)
	]
}
