//
//  UpdateUserSocialMediaDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 5/1/25.
//

struct UpdateUserSocialMediaDTO: Codable, Sendable {
	var whatsappNumber: String?
	var instagramUsername: String?

	enum CodingKeys: String, CodingKey {
		case whatsappNumber
		case instagramUsername
	}
}
