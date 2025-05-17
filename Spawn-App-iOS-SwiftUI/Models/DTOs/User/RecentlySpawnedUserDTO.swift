//
//  RecentlySpawnedUserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-21.
//

import Foundation

struct RecentlySpawnedUserDTO: Identifiable, Codable, Hashable {
    var id: UUID { user.id }
    var user: BaseUserDTO
    var lastEncounteredAt: Date
    
    enum CodingKeys: String, CodingKey {
        case user
        case lastEncounteredAt
    }
}

// Extension with mock data for testing
extension RecentlySpawnedUserDTO {
    static var mockUsers: [RecentlySpawnedUserDTO] {
        BaseUserDTO.mockUsers.map { user in
            RecentlySpawnedUserDTO(
                user: user,
                lastEncounteredAt: Date()
            )
        }
    }
} 