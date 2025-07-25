//
//  UserRelationshipType.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-25.
//

import Foundation

/// Matches the backend UserRelationshipType enum
enum UserRelationshipType: String, Codable, CaseIterable {
    case friend = "FRIEND"
    case recommendedFriend = "RECOMMENDED_FRIEND"
    case incomingFriendRequest = "INCOMING_FRIEND_REQUEST"
    case outgoingFriendRequest = "OUTGOING_FRIEND_REQUEST"
} 