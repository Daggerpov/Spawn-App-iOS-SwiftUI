//
//  BaseUserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-03-04.
//

import Foundation

enum UserStatus: String, Codable, CaseIterable, Sendable {
	case emailVerified = "EMAIL_VERIFIED"
	case usernameAndPhoneNumber = "USERNAME_AND_PHONE_NUMBER"
	case nameAndPhoto = "NAME_AND_PHOTO"
	case contactImport = "CONTACT_IMPORT"
	case active = "ACTIVE"
}

struct BaseUserDTO: Identifiable, Codable, Hashable, Nameable, Sendable {
	static func == (lhs: BaseUserDTO, rhs: BaseUserDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var username: String?
	var profilePicture: String?
	var name: String?
	var bio: String?
	var email: String?
	var hasCompletedOnboarding: Bool?
	var provider: String?  // Auth provider: "google", "apple", or "email"
	var dateCreated: Date?
	var relationshipStatus: UserRelationshipType?  // Relationship status relative to requesting user
	var pendingFriendRequestId: UUID?  // ID of pending friend request if one exists

	init(
		id: UUID,
		username: String? = nil,
		profilePicture: String? = nil,
		name: String? = nil,
		bio: String? = nil,
		email: String? = nil,
		hasCompletedOnboarding: Bool? = nil,
		provider: String? = nil,
		dateCreated: Date? = nil,
		relationshipStatus: UserRelationshipType? = nil,
		pendingFriendRequestId: UUID? = nil
	) {
		self.id = id
		self.username = username
		self.profilePicture = profilePicture
		self.name = name
		self.bio = bio
		self.email = email
		self.hasCompletedOnboarding = hasCompletedOnboarding
		self.provider = provider
		self.dateCreated = dateCreated
		self.relationshipStatus = relationshipStatus
		self.pendingFriendRequestId = pendingFriendRequestId
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
			email: friendUser.email,
			hasCompletedOnboarding: true  // Assume existing friends have completed onboarding
		)
	}

	static let alexRivera: BaseUserDTO = {
		let id: UUID = UUID(uuidString: "7CF00DD1-D246-4339-8B85-0EC589161DBF") ?? UUID()
		return BaseUserDTO(
			id: id,
			username: "alexrivera",
			profilePicture: "Alex_Rivera_pfp",
			name: "Alex Rivera",
			bio: "This is my bio.",
			email: "alex@example.com",
			hasCompletedOnboarding: true
		)
	}()

	static let samCarter: BaseUserDTO = {
		let id: UUID = UUID(uuidString: "8DF11EE2-E357-5440-9C96-1FD690272ECF") ?? UUID()
		return BaseUserDTO(
			id: id,
			username: "samcarter",
			profilePicture: "Sam_Carter_pfp",
			name: "Sam Carter",
			bio: "This is my bio.",
			email: "sam@example.com",
			hasCompletedOnboarding: true
		)
	}()

	static let jamieBrooks: BaseUserDTO = BaseUserDTO(
		id: UUID(uuidString: "9EF22FF3-F468-6551-AD07-2FE7A1383FDA") ?? UUID(),
		username: "jamiebrooks",
		profilePicture: "Jamie_Brooks_pfp",
		name: "Jamie Brooks",
		bio: "This is my bio.",
		email: "jamieBrooks@gmail.com",
		hasCompletedOnboarding: true
	)

	static let mockUsers: [BaseUserDTO] = {
		return [alexRivera, samCarter, jamieBrooks]
	}()
}
