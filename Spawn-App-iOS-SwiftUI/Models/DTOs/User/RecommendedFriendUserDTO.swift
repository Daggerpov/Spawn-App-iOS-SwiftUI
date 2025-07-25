//
//  RecommendedFriendUserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 3/7/25.
//


import Foundation

struct RecommendedFriendUserDTO: Identifiable, Codable, Hashable, Nameable {
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

	init(
		id: UUID,
		username: String? = nil,
		profilePicture: String? = nil,
		name: String? = nil,
		bio: String? = nil,
		email: String?,
        mutualFriendCount: Int? = 0,
        sharedActivitiesCount: Int? = 0
	) {
		self.id = id
		self.username = username
		self.profilePicture = profilePicture
		self.name = name
		self.bio = bio
		self.email = email
        self.mutualFriendCount = mutualFriendCount
        self.sharedActivitiesCount = sharedActivitiesCount
	}
}

extension RecommendedFriendUserDTO {
	static var danielAgapov: RecommendedFriendUserDTO = {
		let id: UUID = UUID()
		return RecommendedFriendUserDTO(
			id: id,
			username: "daggerpov",
			profilePicture: "Daniel_Agapov_pfp",
			name: "Daniel Agapov",
			bio: "This is my bio.",
			email: "daniel@agapov.com"
		)
	}()

	static var danielLee: RecommendedFriendUserDTO = {
		let id: UUID = UUID()
		return RecommendedFriendUserDTO(
			id: id,
			username: "uhdlee",
			profilePicture: "Daniel_Lee_pfp",
			name: "Daniel Lee",
			bio: "This is my bio.",
			email: "daniel2456@gmail.com"
		)
	}()

	static var haley: RecommendedFriendUserDTO = RecommendedFriendUserDTO(
		id: UUID(),
		username: "haleyusername",
		profilePicture: "Haley_pfp",
		name: "Haley",
		bio: "This is my bio.",
		email: "haley@gmail.com",
        mutualFriendCount: 0,
        sharedActivitiesCount: 3
	)

	static let mockUsers: [RecommendedFriendUserDTO] = {
		return [danielAgapov, danielLee, haley]
	}()
}
