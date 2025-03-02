//
//  PotentialFriendUserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-03-01.
//


import Foundation

/// matches `PotentialFriendUserDTO` in the back-end
struct PotentialFriendUserDTO: Identifiable, Codable, Hashable, Nameable {
	static func == (lhs: PotentialFriendUserDTO, rhs: PotentialFriendUserDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var username: String
	var profilePicture: String?
	var firstName: String?
	var lastName: String?
	var bio: String?
	var email: String

	init(
		id: UUID,
		username: String,
		profilePicture: String? = nil,
		firstName: String? = nil,
		lastName: String? = nil,
		bio: String? = nil,
		email: String
	) {
		self.id = id
		self.username = username
		self.profilePicture = profilePicture
		self.firstName = firstName
		self.lastName = lastName
		self.bio = bio
		self.email = email
	}
}

extension PotentialFriendUserDTO {
	static var danielAgapov: PotentialFriendUserDTO = {
		let id: UUID = UUID()
		return PotentialFriendUserDTO(
			id: id,
			username: "daggerpov",
			profilePicture: "Daniel_Agapov_pfp",
			firstName: "Daniel",
			lastName: "Agapov",
			bio: "This is my bio.",
			email: "daniel@agapov.com"
		)
	}()

	static var danielLee: PotentialFriendUserDTO = {
		let id: UUID = UUID()
		return PotentialFriendUserDTO(
			id: id,
			username: "uhdlee",
			profilePicture: "Daniel_Lee_pfp",
			firstName: "Daniel",
			lastName: "Lee",
			bio: "This is my bio.",
			email: "daniel2456@gmail.com"
		)
	}()

	static let mockUsers: [PotentialFriendUserDTO] = {
		return [danielAgapov, danielLee]
	}()
}
