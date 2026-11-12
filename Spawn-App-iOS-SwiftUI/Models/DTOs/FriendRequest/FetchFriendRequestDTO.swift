//
//  FriendRequestDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

/// as defined in the back-end `FetchFriendRequestDTO.java`
struct FetchFriendRequestDTO: Identifiable, Codable, Hashable, Sendable {
	static func == (lhs: FetchFriendRequestDTO, rhs: FetchFriendRequestDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var senderUser: BaseUserDTO
	var mutualFriendCount: Int?

	init(id: UUID = UUID(), senderUser: BaseUserDTO, mutualFriendCount: Int? = 0) {
		self.id = id
		self.senderUser = senderUser
		self.mutualFriendCount = mutualFriendCount
	}
}

extension FetchFriendRequestDTO {
	static let mockFriendRequests: [FetchFriendRequestDTO] = [
		FetchFriendRequestDTO(
			id: UUID(), senderUser: BaseUserDTO.alexRivera),
		FetchFriendRequestDTO(
			id: UUID(),
			senderUser: BaseUserDTO.samCarter,
			mutualFriendCount: 2
		),
	]

	static let mockSentFriendRequests: [FetchFriendRequestDTO] = [
		FetchFriendRequestDTO(
			id: UUID(), senderUser: BaseUserDTO.jamieBrooks),
		FetchFriendRequestDTO(
			id: UUID(),
			senderUser: BaseUserDTO.alexRivera,
			mutualFriendCount: 1
		),
	]

	// Alias for consistency
	static let mockOutgoingFriendRequests: [FetchFriendRequestDTO] = mockSentFriendRequests
}
