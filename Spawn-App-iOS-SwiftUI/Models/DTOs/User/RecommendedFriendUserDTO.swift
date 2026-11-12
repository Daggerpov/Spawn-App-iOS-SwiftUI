//
//  RecommendedFriendUserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 3/7/25.
//

import Foundation

struct RecommendedFriendUserDTO: Identifiable, Codable, Hashable, Nameable, Sendable {
	static func == (lhs: RecommendedFriendUserDTO, rhs: RecommendedFriendUserDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var username: String?
	var profilePicture: String?
	var name: String?
	var bio: String?
	var email: String?
	var mutualFriendCount: Int?
	var sharedActivitiesCount: Int?
	var relationshipStatus: UserRelationshipType?
	var pendingFriendRequestId: UUID?

	init(
		id: UUID,
		username: String? = nil,
		profilePicture: String? = nil,
		name: String? = nil,
		bio: String? = nil,
		email: String?,
		mutualFriendCount: Int? = 0,
		sharedActivitiesCount: Int? = 0,
		relationshipStatus: UserRelationshipType? = .recommendedFriend,
		pendingFriendRequestId: UUID? = nil
	) {
		self.id = id
		self.username = username
		self.profilePicture = profilePicture
		self.name = name
		self.bio = bio
		self.email = email
		self.mutualFriendCount = mutualFriendCount
		self.sharedActivitiesCount = sharedActivitiesCount
		self.relationshipStatus = relationshipStatus
		self.pendingFriendRequestId = pendingFriendRequestId
	}
}

extension RecommendedFriendUserDTO {
	static let alexRivera: RecommendedFriendUserDTO = {
		let id: UUID = UUID()
		return RecommendedFriendUserDTO(
			id: id,
			username: "alexrivera",
			profilePicture: "Alex_Rivera_pfp",
			name: "Alex Rivera",
			bio: "This is my bio.",
			email: "alex@example.com"
		)
	}()

	static let samCarter: RecommendedFriendUserDTO = {
		let id: UUID = UUID()
		return RecommendedFriendUserDTO(
			id: id,
			username: "samcarter",
			profilePicture: "Sam_Carter_pfp",
			name: "Sam Carter",
			bio: "This is my bio.",
			email: "sam@example.com"
		)
	}()

	static let jamieBrooks: RecommendedFriendUserDTO = RecommendedFriendUserDTO(
		id: UUID(),
		username: "jamiebrooks",
		profilePicture: "Jamie_Brooks_pfp",
		name: "Jamie Brooks",
		bio: "This is my bio.",
		email: "jamieBrooks@gmail.com",
		mutualFriendCount: 0,
		sharedActivitiesCount: 3
	)

	static let mockUsers: [RecommendedFriendUserDTO] = {
		return [alexRivera, samCarter, jamieBrooks]
	}()
}
