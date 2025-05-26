//
//  UserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-27.
//

import Foundation

struct UserDTO: Identifiable, Codable, Hashable, Nameable {
	static func == (lhs: UserDTO, rhs: UserDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var friendUserIds: [UUID]?
	var username: String
	var profilePicture: String?
	var name: String?
	var bio: String?
	var email: String

	init(
		id: UUID,
		friendUserIds: [UUID]? = nil,
		username: String,
		profilePicture: String? = nil,
		name: String? = nil,
		bio: String? = nil,
		email: String
	) {
		self.id = id
		self.friendUserIds = friendUserIds
		self.username = username
		self.profilePicture = profilePicture
		self.name = name
		self.bio = bio
		self.email = email
	}
}

extension UserDTO {
	static var danielAgapov: UserDTO = {
		let id: UUID = UUID()
		let friendIds: [UUID] = [UUID(), UUID()]
		return UserDTO(
			id: id,
			friendUserIds: friendIds,
			username: "daggerpov",
			profilePicture: "Daniel_Agapov_pfp",
			name: "Daniel Agapov",
			bio: "This is my bio.",
			email: "daniel@agapov.com"
		)
	}()

	static var danielLee: UserDTO = {
		let id: UUID = UUID()
		return UserDTO(
			id: id,
			friendUserIds: [UUID(), UUID()],
			username: "uhdlee",
			profilePicture: "Daniel_Lee_pfp",
			name: "Daniel Lee",
			bio: "This is my bio.",
			email: "daniel2456@gmail.com"
		)
	}()

	static var shannon: UserDTO = UserDTO(
		id: UUID(),
		friendUserIds: [],
		username: "shannonaurl",
		profilePicture: "Shannon_pfp",
		name: "Shannon",
		bio: "This is my bio.",
		email: "shannon@gmail.com"
	)

	static var jennifer: UserDTO = UserDTO(
		id: UUID(),
		friendUserIds: [],
		username: "jenntjen",
		profilePicture: "Jennifer_pfp",
		name: "Jennifer Tjen",
		bio: "This is my bio.",
		email: "jennifer@gmail.com"
	)

	static var michael: UserDTO = UserDTO(
		id: UUID(),
		friendUserIds: [],
		username: "michaeltham",
		profilePicture: "Michael_pfp",
		name: "Michael Tham",
		bio: "This is my bio.",
		email: "haley@gmail.com"
	)

	static var haley: UserDTO = UserDTO(
		id: UUID(),
		friendUserIds: [],
		username: "haleyusername",
		profilePicture: "Haley_pfp",
		name: "Haley",
		bio: "This is my bio.",
		email: "haley@gmail.com"
	)

	static let mockUsers: [UserDTO] = {
		return [danielAgapov, shannon, jennifer, michael, haley]
	}()
}
