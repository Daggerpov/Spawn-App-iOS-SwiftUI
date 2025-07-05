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
	var username: String
	var profilePicture: String?
	var name: String?
	var bio: String?
	var email: String
    var mutualFriendCount: Int?

	init(
		id: UUID,
		username: String,
		profilePicture: String? = nil,
		name: String? = nil,
		bio: String? = nil,
		email: String,
        mutualFriendCount: Int? = 0
	) {
		self.id = id
		self.username = username
		self.profilePicture = profilePicture
		self.name = name
		self.bio = bio
		self.email = email
        self.mutualFriendCount = mutualFriendCount
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

	static var shannon: RecommendedFriendUserDTO = RecommendedFriendUserDTO(
		id: UUID(),
		username: "shannonaurl",
		profilePicture: "Shannon_pfp",
		name: "Shannon",
		bio: "This is my bio.",
		email: "shannon@gmail.com",
        mutualFriendCount: 3
	)

	static var jennifer: RecommendedFriendUserDTO = RecommendedFriendUserDTO(
		id: UUID(),
		username: "jenntjen",
		profilePicture: "Jennifer_pfp",
		name: "Jennifer Tjen",
		bio: "This is my bio.",
		email: "jennifer@gmail.com",
        mutualFriendCount: 1
	)

	static var michael: RecommendedFriendUserDTO = RecommendedFriendUserDTO(
		id: UUID(),
		username: "michaeltham",
		profilePicture: "Michael_pfp",
		name: "Michael Tham",
		bio: "This is my bio.",
		email: "haley@gmail.com",
        mutualFriendCount: 2
	)

	static var haley: RecommendedFriendUserDTO = RecommendedFriendUserDTO(
		id: UUID(),
		username: "haleyusername",
		profilePicture: "Haley_pfp",
		name: "Haley",
		bio: "This is my bio.",
		email: "haley@gmail.com",
        mutualFriendCount: 0
	)

	static let mockUsers: [RecommendedFriendUserDTO] = {
		return [danielAgapov, shannon, jennifer, michael, haley]
	}()
}
