//
//  FullFriendUserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import Foundation

/// matches `FullFriendUserDTO` in the back-end
struct FullFriendUserDTO: Identifiable, Codable, Hashable, Nameable {
	static func == (lhs: FullFriendUserDTO, rhs: FullFriendUserDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var username: String
	var profilePicture: String?
	var name: String?
	var bio: String?
	var email: String

	init(
		id: UUID,
		username: String,
		profilePicture: String? = nil,
		name: String? = nil,
		bio: String? = nil,
		email: String,
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
	static var danielAgapov: FullFriendUserDTO = {
		let id: UUID = UUID()
		return FullFriendUserDTO(
			id: id,
			username: "daggerpov",
			profilePicture: "Daniel_Agapov_pfp",
			name: "Daniel Agapov",
			bio: "This is my bio.",
			email: "daniel@agapov.com",
		)
	}()

	static var danielLee: FullFriendUserDTO = {
		let id: UUID = UUID()
		return FullFriendUserDTO(
			id: id,
			username: "uhdlee",
			profilePicture: "Daniel_Lee_pfp",
			name: "Daniel Lee",
			bio: "This is my bio.",
			email: "daniel2456@gmail.com",
		)
	}()

	static let mockUsers: [FullFriendUserDTO] = {
		return [danielAgapov, danielLee]
	}()
}
