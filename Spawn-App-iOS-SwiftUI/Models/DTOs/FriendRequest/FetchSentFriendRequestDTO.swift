//
//  FetchSentFriendRequestDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

/// as defined in the back-end `FetchSentFriendRequestDTO.java`
struct FetchSentFriendRequestDTO: Identifiable, Codable, Hashable {
	static func == (lhs: FetchSentFriendRequestDTO, rhs: FetchSentFriendRequestDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var receiverUser: BaseUserDTO

	init(id: UUID = UUID(), receiverUser: BaseUserDTO) {
		self.id = id
		self.receiverUser = receiverUser
	}
}

extension FetchSentFriendRequestDTO {
	static let mockSentFriendRequests: [FetchSentFriendRequestDTO] = [
		FetchSentFriendRequestDTO(
			id: UUID(), receiverUser: BaseUserDTO.haley),
		FetchSentFriendRequestDTO(
			id: UUID(),
			receiverUser: BaseUserDTO.danielAgapov
		),
	]

	// Alias for consistency
	static let mockOutgoingFriendRequests: [FetchSentFriendRequestDTO] = mockSentFriendRequests
}
