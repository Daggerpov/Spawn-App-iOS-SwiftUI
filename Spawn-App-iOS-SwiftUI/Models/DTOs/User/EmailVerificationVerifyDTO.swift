//
//  EmailVerificationVerifyDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 2025-01-28.
//

struct EmailVerificationVerifyDTO: Codable, Sendable {
	let email: String
	let verificationCode: String
}
