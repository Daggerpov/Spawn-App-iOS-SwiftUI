//
//  BaseUserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-03-04.
//

import Foundation

struct BaseUserDTO: Identifiable, Codable, Hashable, Nameable {
	static func == (lhs: BaseUserDTO, rhs: BaseUserDTO) -> Bool {
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

extension BaseUserDTO {
	static var danielAgapov: BaseUserDTO = {
        let id: UUID = UUID(uuidString: "7CF00DD1-D246-4339-8B85-0EC589161DBF") ?? UUID()
		return BaseUserDTO(
			id: id,
			username: "daggerpov",
			profilePicture: "Daniel_Agapov_pfp",
			firstName: "Daniel",
			lastName: "Agapov",
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
			firstName: "Daniel",
			lastName: "Lee",
			bio: "This is my bio.",
			email: "daniel2456@gmail.com"
		)
	}()

	static var shannon: BaseUserDTO = BaseUserDTO(
		id: UUID(),
		username: "shannonaurl",
		profilePicture: "Shannon_pfp",
		firstName: "Shannon",
		bio: "This is my bio.",
		email: "shannon@gmail.com"
	)

	static var jennifer: BaseUserDTO = BaseUserDTO(
		id: UUID(),
		username: "jenntjen",
		profilePicture: "Jennifer_pfp",
		firstName: "Jennifer",
		lastName: "Tjen",
		bio: "This is my bio.",
		email: "jennifer@gmail.com"
	)

	static var michael: BaseUserDTO = BaseUserDTO(
		id: UUID(),
		username: "michaeltham",
		profilePicture: "Michael_pfp",
		firstName: "Michael",
		lastName: "Tham",
		bio: "This is my bio.",
		email: "haley@gmail.com"
	)

	static var haley: BaseUserDTO = BaseUserDTO(
		id: UUID(),
		username: "haleyusername",
		profilePicture: "Haley_pfp",
		firstName: "Haley",
		bio: "This is my bio.",
		email: "haley@gmail.com"
	)

	static let mockUsers: [BaseUserDTO] = {
		return [danielAgapov, shannon, jennifer, michael, haley]
	}()
}
