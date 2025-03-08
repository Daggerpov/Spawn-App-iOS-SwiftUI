//
//  FullFriendUserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import Foundation

/// matches `FullFriendUserDTO` in the back-end
struct FullFriendUserDTO: Identifiable, Codable, Hashable {
	static func == (lhs: FullFriendUserDTO, rhs: FullFriendUserDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var username: String
	var profilePicture: String?
	var firstName: String?
	var lastName: String?
	var bio: String?
	var email: String
	var associatedFriendTagsToOwner: [FriendTagDTO]?  // only added property from `User`

	init(
		id: UUID,
		username: String,
		profilePicture: String? = nil,
		firstName: String? = nil,
		lastName: String? = nil,
		bio: String? = nil,
		email: String,
		associatedFriendTagsToOwner: [FriendTagDTO]? = nil
	) {
		self.id = id
		self.username = username
		self.profilePicture = profilePicture
		self.firstName = firstName
		self.lastName = lastName
		self.bio = bio
		self.email = email
		self.associatedFriendTagsToOwner = associatedFriendTagsToOwner
	}
}

extension FullFriendUserDTO {
	static var danielAgapov: FullFriendUserDTO = {
		let id: UUID = UUID()
		return FullFriendUserDTO(
			id: id,
			username: "daggerpov",
			profilePicture: "Daniel_Agapov_pfp",
			firstName: "Daniel",
			lastName: "Agapov",
			bio: "This is my bio.",
			email: "daniel@agapov.com",
			associatedFriendTagsToOwner: [
				FriendTagDTO(
					id: UUID(),
					displayName: "Close Friends",
					ownerUserId: UUID(),
					colorHexCode: eventColorHexCodes[1]
				),
				FriendTagDTO(
					id: UUID(),
					displayName: "Hobbies",
					ownerUserId: UUID(),
					colorHexCode: eventColorHexCodes[2]
				),
			]
		)
	}()

	static var danielLee: FullFriendUserDTO = {
		let id: UUID = UUID()
		return FullFriendUserDTO(
			id: id,
			username: "uhdlee",
			profilePicture: "Daniel_Lee_pfp",
			firstName: "Daniel",
			lastName: "Lee",
			bio: "This is my bio.",
			email: "daniel2456@gmail.com",
			associatedFriendTagsToOwner: [
				FriendTagDTO(
					id: UUID(),
					displayName: "Basketball",
					ownerUserId: UUID(),
					colorHexCode: eventColorHexCodes[0]
				),
				FriendTagDTO(
					id: UUID(),
					displayName: "Close Friends",
					ownerUserId: UUID(),
					colorHexCode: eventColorHexCodes[1]
				),
				FriendTagDTO(
					id: UUID(),
					displayName: "Hobbies",
					ownerUserId: UUID(),
					colorHexCode: eventColorHexCodes[2]
				),
			]
		)
	}()

	static let mockUsers: [FullFriendUserDTO] = {
		return [danielAgapov, danielLee]
	}()
}
