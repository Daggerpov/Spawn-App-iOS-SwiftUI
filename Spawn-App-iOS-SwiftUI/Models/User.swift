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
    static let danielAgapov: User = User(id: UUID(), friends: [])
    static let danielLee: User = User(id: UUID(), friends: [])
    static let shannon: User = User(id: UUID(), friends: [])
    static let jennifer: User = User(id: UUID(), friends: [])
    static let michael: User = User(id: UUID(), friends: [])
    static let haley: User = User(id: UUID(), friends: [])
    
    static func setupFriends() {
        danielAgapov.friends = [danielLee, shannon, jennifer, michael, haley]
        danielLee.friends = [danielAgapov, jennifer, haley]
        shannon.friends = [danielAgapov, danielLee]
        jennifer.friends = [danielAgapov, danielLee, shannon]
        michael.friends = [danielAgapov, danielLee, shannon, jennifer]
        haley.friends = [danielAgapov, danielLee, shannon, jennifer, michael]
    }
    
    static let mockUsers: [User] = {
        setupFriends()
        return [
            danielAgapov,
            danielLee,
            shannon,
            jennifer,
            michael,
            haley
        ]
    }()
    
    static let emptyUser: User = User(id: UUID(), friends: [])
}
