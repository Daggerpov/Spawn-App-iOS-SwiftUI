//
//  ProfileEventDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-06-15.
//

import Foundation

class ProfileEventDTO: FullFeedEventDTO {
    var isPastEvent: Bool
    
    // Custom initializer to handle the additional property
    init(
        id: UUID,
        title: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        location: Location? = nil,
        note: String? = nil,
        icon: String? = nil,
        category: EventCategory = .general,
        creatorUser: BaseUserDTO,
        participantUsers: [BaseUserDTO]? = nil,
        invitedUsers: [BaseUserDTO]? = nil,
        chatMessages: [FullEventChatMessageDTO]? = nil,
        eventFriendTagColorHexCodeForRequestingUser: String? = nil,
        participationStatus: ParticipationStatus? = nil,
        isSelfOwned: Bool? = nil,
        isPastEvent: Bool = false
    ) {
        self.isPastEvent = isPastEvent
        
        super.init(
            id: id,
            title: title,
            startTime: startTime,
            endTime: endTime,
            location: location,
            note: note,
            icon: icon,
            category: category,
            creatorUser: creatorUser,
            participantUsers: participantUsers,
            invitedUsers: invitedUsers,
            chatMessages: chatMessages,
            eventFriendTagColorHexCodeForRequestingUser: eventFriendTagColorHexCodeForRequestingUser,
            participationStatus: participationStatus,
            isSelfOwned: isSelfOwned
        )
    }
    
    // Required for Codable conformance
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isPastEvent = try container.decode(Bool.self, forKey: .isPastEvent)
        try super.init(from: decoder)
    }
    
    // CodingKeys to handle the additional property
    private enum CodingKeys: String, CodingKey {
        case isPastEvent
    }
    
    // Encoding method to handle the additional property
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isPastEvent, forKey: .isPastEvent)
    }
    
    // Convert a FullFeedEventDTO to a ProfileEventDTO
    static func from(fullFeedEventDTO: FullFeedEventDTO, isPastEvent: Bool) -> ProfileEventDTO {
        return ProfileEventDTO(
            id: fullFeedEventDTO.id,
            title: fullFeedEventDTO.title,
            startTime: fullFeedEventDTO.startTime,
            endTime: fullFeedEventDTO.endTime,
            location: fullFeedEventDTO.location,
            note: fullFeedEventDTO.note,
            icon: fullFeedEventDTO.icon,
            category: fullFeedEventDTO.category,
            creatorUser: fullFeedEventDTO.creatorUser,
            participantUsers: fullFeedEventDTO.participantUsers,
            invitedUsers: fullFeedEventDTO.invitedUsers,
            chatMessages: fullFeedEventDTO.chatMessages,
            eventFriendTagColorHexCodeForRequestingUser: fullFeedEventDTO.eventFriendTagColorHexCodeForRequestingUser,
            participationStatus: fullFeedEventDTO.participationStatus,
            isSelfOwned: fullFeedEventDTO.isSelfOwned,
            isPastEvent: isPastEvent
        )
    }
} 