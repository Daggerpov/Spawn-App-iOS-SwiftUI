//
//  SearchedUserResult.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-25.
//

import Foundation

/// Matches the backend SearchedUserResult class
struct SearchedUserResult: Codable, Hashable, Sendable {
	var users: [SearchResultUserDTO]

	init(users: [SearchResultUserDTO]) {
		self.users = users
	}
}
