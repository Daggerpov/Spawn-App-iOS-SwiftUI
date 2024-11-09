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
	static let danielAgapov: User = {
		let user = User(id: UUID())
		user.friends = User.mockUsers.filter { $0.id != user.id }
		return user
	}()
    static let danielLee: User = User(id: UUID(), friends: [danielAgapov])
	static let shannon: User = User(id: UUID(), friends: [danielAgapov, danielLee])
	static let jennifer: User = User(id: UUID(), friends: [danielAgapov, danielLee, shannon])
	static let michael: User = User(id: UUID(), friends: [danielAgapov, danielLee, shannon, jennifer])
	static let haley: User = User(id: UUID(), friends: [danielAgapov, danielLee, shannon, jennifer, michael])

    static let mockUsers: [User] = [
        danielAgapov,
        danielLee,
		shannon,
		jennifer,
		michael,
		haley
    ]
}
