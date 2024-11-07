//
//  User.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

struct User: Identifiable, Codable {
    var id: UUID
    var friends: [User]?
}

extension User {
    static let danielAgapov: User = User(id: UUID())
    
    static let danielLee: User = User(id: UUID(), friends: [danielAgapov])
    
    static let mockUsers: [User] = [
        danielAgapov,
        danielLee
    ]
}
