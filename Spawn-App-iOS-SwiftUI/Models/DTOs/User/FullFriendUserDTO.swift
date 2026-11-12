//
//  FullFriendUserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import Foundation

/// matches `FullFriendUserDTO` in the back-end
struct FullFriendUserDTO: Identifiable, Codable, Hashable, Nameable, Sendable {
	static func == (lhs: FullFriendUserDTO, rhs: FullFriendUserDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var username: String?
	var profilePicture: String?
	var name: String?
	var bio: String?
	var email: String?

	init(
		id: UUID,
		username: String? = nil,
		profilePicture: String? = nil,
		name: String? = nil,
		bio: String? = nil,
		email: String?
	) {
		self.id = id
		self.username = username
		self.profilePicture = profilePicture
		self.name = name
		self.bio = bio
		self.email = email
	}
}

extension FullFriendUserDTO {
	static let alexRivera: FullFriendUserDTO = {
		let id: UUID = UUID()
		return FullFriendUserDTO(
			id: id,
			username: "alexrivera",
			profilePicture: "Alex_Rivera_pfp",
			name: "Alex Rivera",
			bio: "This is my bio.",
			email: "alex@example.com"
		)
	}()

	static let samCarter: FullFriendUserDTO = {
		let id: UUID = UUID()
		return FullFriendUserDTO(
			id: id,
			username: "samcarter",
			profilePicture: "Sam_Carter_pfp",
			name: "Sam Carter",
			bio: "This is my bio.",
			email: "sam@example.com"
		)
	}()

	static let mockUsers: [FullFriendUserDTO] = {
		return [alexRivera, samCarter]
	}()
}
