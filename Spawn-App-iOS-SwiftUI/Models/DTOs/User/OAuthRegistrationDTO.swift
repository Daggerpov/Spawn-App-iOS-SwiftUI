//
//  OAuthRegistrationDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 2025-01-28.
//

struct OAuthRegistrationDTO: Codable {
	let idToken: String
	let provider: String
	let email: String?
	let name: String?
	let profilePictureUrl: String?
}
