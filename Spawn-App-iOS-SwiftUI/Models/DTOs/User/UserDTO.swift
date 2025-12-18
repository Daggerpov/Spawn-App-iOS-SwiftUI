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
	static let danielAgapov: UserDTO = {
		let id: UUID = UUID()
		let friendIds: [UUID] = [UUID(), UUID()]
		return UserDTO(
			id: id,
			friendUserIds: friendIds,
			username: "daggerpov",
			profilePicture: "Daniel_Agapov_pfp",
			name: "Daniel Agapov",
			bio: "This is my bio.",
			email: "daniel@agapov.com",
			hasCompletedOnboarding: true
		)
	}()

	static let danielLee: UserDTO = {
		let id: UUID = UUID()
		return UserDTO(
			id: id,
			friendUserIds: [UUID(), UUID()],
			username: "uhdlee",
			profilePicture: "Daniel_Lee_pfp",
			name: "Daniel Lee",
			bio: "This is my bio.",
			email: "daniel2456@gmail.com",
			hasCompletedOnboarding: true
		)
	}()

	static let haley: UserDTO = UserDTO(
		id: UUID(),
		friendUserIds: [],
		username: "haleyusername",
		profilePicture: "Haley_pfp",
		name: "Haley",
		bio: "This is my bio.",
		email: "haley@gmail.com",
		hasCompletedOnboarding: true
	)

	static let mockUsers: [UserDTO] = {
		return [danielAgapov, danielLee, haley]
	}()
}
