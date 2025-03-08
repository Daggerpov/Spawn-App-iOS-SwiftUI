//
//  RecommendedFriendUserDTO 2.swift
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
	var firstName: String?
	var lastName: String?
	var bio: String?
	var email: String
    var mutualFriendCount: Int?

	init(
		id: UUID,
		username: String,
		profilePicture: String? = nil,
		firstName: String? = nil,
		lastName: String? = nil,
		bio: String? = nil,
		email: String,
        mutualFriendCount: Int? = 0
	) {
		self.id = id
		self.username = username
		self.profilePicture = profilePicture
		self.firstName = firstName
		self.lastName = lastName
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
			firstName: "Daniel",
			lastName: "Agapov",
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
			firstName: "Daniel",
			lastName: "Lee",
			bio: "This is my bio.",
			email: "daniel2456@gmail.com"
		)
	}()

	static var shannon: RecommendedFriendUserDTO = RecommendedFriendUserDTO(
		id: UUID(),
		username: "shannonaurl",
		profilePicture: "Shannon_pfp",
		firstName: "Shannon",
		bio: "This is my bio.",
		email: "shannon@gmail.com"
	)

	static var jennifer: RecommendedFriendUserDTO = RecommendedFriendUserDTO(
		id: UUID(),
		username: "jenntjen",
		profilePicture: "Jennifer_pfp",
		firstName: "Jennifer",
		lastName: "Tjen",
		bio: "This is my bio.",
		email: "jennifer@gmail.com"
	)

	static var michael: RecommendedFriendUserDTO = RecommendedFriendUserDTO(
		id: UUID(),
		username: "michaeltham",
		profilePicture: "Michael_pfp",
		firstName: "Michael",
		lastName: "Tham",
		bio: "This is my bio.",
		email: "haley@gmail.com"
	)

	static var haley: RecommendedFriendUserDTO = RecommendedFriendUserDTO(
		id: UUID(),
		username: "haleyusername",
		profilePicture: "Haley_pfp",
		firstName: "Haley",
		bio: "This is my bio.",
		email: "haley@gmail.com"
	)

	static let mockUsers: [RecommendedFriendUserDTO] = {
		return [danielAgapov, shannon, jennifer, michael, haley]
	}()
}
