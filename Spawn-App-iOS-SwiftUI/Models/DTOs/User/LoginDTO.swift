//
//  LoginDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/2/25.
//

struct LoginDTO: Codable, Hashable, Sendable {
	static func == (lhs: LoginDTO, rhs: LoginDTO) -> Bool {
		return lhs.usernameOrEmail == rhs.usernameOrEmail
	}

	let usernameOrEmail: String
	let password: String

	init(usernameOrEmail: String, password: String) {
		self.usernameOrEmail = usernameOrEmail
		self.password = password
	}
}
