//
//  AuthResponseDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by System on 2025-01-29.
//

import Foundation

struct AuthResponseDTO: Identifiable, Codable, Hashable, Nameable {
	static func == (lhs: AuthResponseDTO, rhs: AuthResponseDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var username: String
	var profilePicture: String?
	var name: String?
	var bio: String?
	var email: String
	var status: UserStatus?

	init(
		id: UUID,
		username: String,
		profilePicture: String? = nil,
		name: String? = nil,
		bio: String? = nil,
		email: String,
		status: UserStatus? = nil
	) {
		self.id = id
		self.username = username
		self.profilePicture = profilePicture
		self.name = name
		self.bio = bio
		self.email = email
		self.status = status
	}
}

extension AuthResponseDTO {
	// Convert to BaseUserDTO for compatibility with existing code
	func toBaseUserDTO() -> BaseUserDTO {
		return BaseUserDTO(
			id: self.id,
			username: self.username,
			profilePicture: self.profilePicture,
			name: self.name,
			bio: self.bio,
			email: self.email
		)
	}
} 