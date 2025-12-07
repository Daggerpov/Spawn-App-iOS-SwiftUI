//
//  CacheValidationResponse.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-04-20.
//

import Foundation

struct CacheValidationResponse: Codable, Sendable {
	var invalidate: Bool
	var updatedItems: Data?
}
