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
    var mutualFriendCount: Int?

    init(id: UUID, senderUser: BaseUserDTO, mutualFriendCount: Int? = 0) {
		self.id = id
		self.senderUser = senderUser
        self.mutualFriendCount = mutualFriendCount
	}
}

extension FetchFriendRequestDTO {
	static let mockFriendRequests: [FetchFriendRequestDTO] = [
		FetchFriendRequestDTO(
			id: UUID(), senderUser: BaseUserDTO.danielAgapov),
		FetchFriendRequestDTO(
			id: UUID(),
			senderUser: BaseUserDTO.danielLee,
            mutualFriendCount: 2
		)
	]
    
    static let mockSentFriendRequests: [FetchFriendRequestDTO] = [
        FetchFriendRequestDTO(
            id: UUID(), senderUser: BaseUserDTO.haley),
        FetchFriendRequestDTO(
            id: UUID(),
            senderUser: BaseUserDTO.jennifer,
            mutualFriendCount: 1
        )
    ]
    
    // Alias for consistency
    static let mockOutgoingFriendRequests: [FetchFriendRequestDTO] = mockSentFriendRequests
}
