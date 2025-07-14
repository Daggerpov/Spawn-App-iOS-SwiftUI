//
//  BaseUserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-03-04.
//

import Foundation

enum UserStatus: String, Codable, CaseIterable {
    case emailVerified = "EMAIL_VERIFIED"
    case usernameAndPhoneNumber = "USERNAME_AND_PHONE_NUMBER"
    case nameAndPhoto = "NAME_AND_PHOTO"
    case active = "ACTIVE"
}

struct BaseUserDTO: Identifiable, Codable, Hashable, Nameable {
	static func == (lhs: BaseUserDTO, rhs: BaseUserDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var username: String
	var profilePicture: String?
	var name: String?
	var bio: String?
	var email: String?

	init(
		id: UUID,
		username: String,
		profilePicture: String? = nil,
		name: String? = nil,
		bio: String? = nil,
		email: String? = nil
	) {
		self.id = id
		self.username = username
		self.profilePicture = profilePicture
		self.name = name
		self.bio = bio
		self.email = email
	}
}

extension BaseUserDTO {
	static func from(friendUser: FullFriendUserDTO) -> BaseUserDTO {
		return BaseUserDTO(
			id: friendUser.id,
			username: friendUser.username,
			profilePicture: friendUser.profilePicture,
			name: friendUser.name,
			bio: friendUser.bio,
			email: friendUser.email
		)
	}

	static var danielAgapov: BaseUserDTO = {
        let id: UUID = UUID(uuidString: "7CF00DD1-D246-4339-8B85-0EC589161DBF") ?? UUID()
		return BaseUserDTO(
			id: id,
			username: "daggerpov",
			profilePicture: "Daniel_Agapov_pfp",
			name: "Daniel Agapov",
			bio: "This is my bio.",
			email: "daniel@agapov.com"
		)
	}()

	static var danielLee: BaseUserDTO = {
		let id: UUID = UUID()
		return BaseUserDTO(
			id: id,
			username: "uhdlee",
			profilePicture: "Daniel_Lee_pfp",
			name: "Daniel Lee",
			bio: "This is my bio.",
			email: "daniel2456@gmail.com"
		)
	}()

	static var haley: BaseUserDTO = BaseUserDTO(
		id: UUID(),
		username: "haleyusername",
		profilePicture: "Haley_pfp",
		name: "Haley",
		bio: "This is my bio.",
		email: "haley@gmail.com"
	)

	static let mockUsers: [BaseUserDTO] = {
		return [danielAgapov, danielLee, haley]
	}()
}
