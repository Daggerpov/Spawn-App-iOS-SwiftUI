//
//  ActivityCreationResponseDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2025-01-03.
//

import Foundation

struct ActivityCreationResponseDTO: Codable {
    let activity: FullFeedActivityDTO
    let friendSuggestion: ActivityTypeFriendSuggestionDTO?
    
    init(activity: FullFeedActivityDTO, friendSuggestion: ActivityTypeFriendSuggestionDTO? = nil) {
        self.activity = activity
        self.friendSuggestion = friendSuggestion
    }
}

struct ActivityTypeFriendSuggestionDTO: Codable {
    let activityTypeId: UUID
    let activityTypeTitle: String
    let suggestedFriends: [BaseUserDTO]
    let shouldShowPrompt: Bool
    
    init(activityTypeId: UUID, activityTypeTitle: String, suggestedFriends: [BaseUserDTO]) {
        self.activityTypeId = activityTypeId
        self.activityTypeTitle = activityTypeTitle
        self.suggestedFriends = suggestedFriends
        self.shouldShowPrompt = !suggestedFriends.isEmpty
    }
}
