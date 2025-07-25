//
//  ActivityInviteDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-17.
//

import Foundation

/// DTO for external activity invites - contains only essential information
/// needed for the activity invite page without requiring authentication
class ActivityInviteDTO: Identifiable, Codable {
    var id: UUID
    var title: String?
    
    // MARK: Info
    var startTime: Date?
    var endTime: Date?
    var location: LocationDTO?
    var note: String?
    /* The icon is stored as a Unicode emoji character string (e.g. "⭐️", "🎉", "🏀").
       This is the literal emoji character, not a shortcode or description.
       It's rendered directly in the UI and stored as a single UTF-8 string in the database. */
    var icon: String?
    var participantLimit: Int? // nil means unlimited participants
    var createdAt: Date?
    
    // MARK: Relations
    var locationId: UUID?
    var activityTypeId: UUID?
    var creatorUserId: UUID
    var participantUserIds: [UUID]?
    var invitedUserIds: [UUID]?
    
    init(
        id: UUID,
        title: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        location: LocationDTO? = nil,
        locationId: UUID? = nil,
        activityTypeId: UUID? = nil,
        note: String? = nil,
        icon: String? = nil,
        participantLimit: Int? = nil,
        creatorUserId: UUID,
        participantUserIds: [UUID]? = nil,
        invitedUserIds: [UUID]? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.locationId = locationId
        self.activityTypeId = activityTypeId
        self.note = note
        self.icon = icon
        self.participantLimit = participantLimit
        self.creatorUserId = creatorUserId
        self.participantUserIds = participantUserIds
        self.invitedUserIds = invitedUserIds
        self.createdAt = createdAt
    }
} 