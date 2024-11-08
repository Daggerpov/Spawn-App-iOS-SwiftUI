//
//  User.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

class User: Identifiable, Codable {
    var id: UUID
    var friends: [User]?

	init(id: UUID, friends: [User]? = nil) {
		self.id = id
		self.friends = friends
	}
}

extension User {
    static let danielAgapov: User = User(id: UUID())
    
    static let danielLee: User = User(id: UUID(), friends: [danielAgapov])
    
    static let mockUsers: [User] = [
        danielAgapov,
        danielLee
    ]
}
