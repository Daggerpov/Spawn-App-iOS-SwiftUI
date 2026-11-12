//
//  UserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-27.
//

import Foundation

struct UserDTO: Identifiable, Codable, Hashable, Nameable, Sendable {
	static func == (lhs: UserDTO, rhs: UserDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var friendUserIds: [UUID]?
	var username: String?
	var profilePicture: String?
	var name: String?
	var bio: String?
	var email: String
	var hasCompletedOnboarding: Bool?

	init(
		id: UUID,
		friendUserIds: [UUID]? = nil,
		username: String? = nil,
		profilePicture: String? = nil,
		name: String? = nil,
		bio: String? = nil,
		email: String,
		hasCompletedOnboarding: Bool? = nil
	) {
		self.id = id
		self.friendUserIds = friendUserIds
		self.username = username
		self.profilePicture = profilePicture
		self.name = name
		self.bio = bio
		self.email = email
		self.hasCompletedOnboarding = hasCompletedOnboarding
	}
}

extension UserDTO {
	static let alexRivera: UserDTO = {
		let id: UUID = UUID()
		let friendIds: [UUID] = [UUID(), UUID()]
		return UserDTO(
			id: id,
			friendUserIds: friendIds,
			username: "alexrivera",
			profilePicture: "Alex_Rivera_pfp",
			name: "Alex Rivera",
			bio: "This is my bio.",
			email: "alex@example.com",
			hasCompletedOnboarding: true
		)
	}()

	static let samCarter: UserDTO = {
		let id: UUID = UUID()
		return UserDTO(
			id: id,
			friendUserIds: [UUID(), UUID()],
			username: "samcarter",
			profilePicture: "Sam_Carter_pfp",
			name: "Sam Carter",
			bio: "This is my bio.",
			email: "sam@example.com",
			hasCompletedOnboarding: true
		)
	}()

	static let jamieBrooks: UserDTO = UserDTO(
		id: UUID(),
		friendUserIds: [],
		username: "jamiebrooks",
		profilePicture: "Jamie_Brooks_pfp",
		name: "Jamie Brooks",
		bio: "This is my bio.",
		email: "jamieBrooks@gmail.com",
		hasCompletedOnboarding: true
	)

	static let mockUsers: [UserDTO] = {
		return [alexRivera, samCarter, jamieBrooks]
	}()
}
