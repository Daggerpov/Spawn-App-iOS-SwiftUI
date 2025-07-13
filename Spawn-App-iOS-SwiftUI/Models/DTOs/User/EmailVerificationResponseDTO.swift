//
//  EmailVerificationResponseDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 2025-01-28.
//

struct EmailVerificationResponseDTO: Codable {
    let secondsUntilNextAttempt: Int
    let message: String
} 