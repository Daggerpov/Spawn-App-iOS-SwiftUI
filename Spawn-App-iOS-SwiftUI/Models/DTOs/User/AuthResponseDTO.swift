//
//  AuthResponseDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by System on 2025-01-29.
//

import Foundation

struct AuthResponseDTO: Codable {
	var user: BaseUserDTO
	var status: UserStatus?
	var isOAuthUser: Bool?

	init(user: BaseUserDTO, status: UserStatus? = nil) {
		self.user = user
		self.status = status
	}
}

extension AuthResponseDTO {
	// Convert to BaseUserDTO for compatibility with existing code
	func toBaseUserDTO() -> BaseUserDTO {
		return self.user
	}
}
