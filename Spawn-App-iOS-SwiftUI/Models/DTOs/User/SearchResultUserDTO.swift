//
//  SearchResultUserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-25.
//

import Foundation

/// Matches the backend SearchResultUserDTO class
struct SearchResultUserDTO: Identifiable, Codable, Hashable {
	var id: UUID { user.id }

	var user: BaseUserDTO
	var relationshipType: UserRelationshipType
	var mutualFriendCount: Int?  // Optional, only for recommended friends
	var friendRequestId: UUID?  // Optional, only for friend requests

	init(
		user: BaseUserDTO,
		relationshipType: UserRelationshipType,
		mutualFriendCount: Int? = nil,
		friendRequestId: UUID? = nil
	) {
		self.user = user
		self.relationshipType = relationshipType
		self.mutualFriendCount = mutualFriendCount
		self.friendRequestId = friendRequestId
	}
}
