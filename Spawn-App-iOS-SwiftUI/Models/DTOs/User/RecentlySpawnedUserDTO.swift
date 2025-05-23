//
//  RecentlySpawnedUserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-21.
//

import Foundation

struct RecentlySpawnedUserDTO: Codable, Hashable {
    var user: BaseUserDTO
    var dateTime: Date
}
