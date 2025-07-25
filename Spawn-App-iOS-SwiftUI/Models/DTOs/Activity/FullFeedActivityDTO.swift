//
//  FullFeedActivityDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-27.
//

import Foundation

class FullFeedActivityDTO: Identifiable, Codable, Equatable, ObservableObject {
	static func == (lhs: FullFeedActivityDTO, rhs: FullFeedActivityDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var title: String?

	// MARK: Info
	var startTime: Date?
	var endTime: Date?
    var location: LocationDTO?
	var note: String?  // this corresponds to Figma design "my place at 10? I'm cooking guys" note in activity
	/* The icon is stored as a Unicode emoji character string (e.g. "⭐️", "🎉", "🏀").
	   This is the literal emoji character, not a shortcode or description.
	   It's rendered directly in the UI and stored as a single UTF-8 string in the database. */
	var icon: String?
	var participantLimit: Int? // nil means unlimited participants
	var createdAt: Date?

	// MARK: Relations
	var activityTypeId: UUID?
	var creatorUser: BaseUserDTO

	// tech note: I'll be able to check if current user is in an activity's partipants to determine which symbol to show in feed
	var participantUsers: [BaseUserDTO]?
	var invitedUsers: [BaseUserDTO]?
	@Published var chatMessages: [FullActivityChatMessageDTO]?
	@Published var participationStatus: ParticipationStatus?
	var isSelfOwned: Bool?

	init(
		id: UUID,
		title: String? = nil,
		startTime: Date? = nil,
		endTime: Date? = nil,
		location: LocationDTO? = nil,
		activityTypeId: UUID? = nil,
		note: String? = nil,
		icon: String? = nil,
		participantLimit: Int? = nil,
		creatorUser: BaseUserDTO,
		participantUsers: [BaseUserDTO]? = nil,
		invitedUsers: [BaseUserDTO]? = nil,
		chatMessages: [FullActivityChatMessageDTO]? = nil,
		participationStatus: ParticipationStatus? = nil,
		isSelfOwned: Bool? = nil,
		createdAt: Date? = nil
	) {
		self.id = id
		self.title = title
		self.startTime = startTime
		self.endTime = endTime
		self.location = location
		self.activityTypeId = activityTypeId
		self.note = note
		self.icon = icon
		self.participantLimit = participantLimit
		self.creatorUser = creatorUser
		self.participantUsers = participantUsers
		self.invitedUsers = invitedUsers
		self.chatMessages = chatMessages
		self.participationStatus = participationStatus
		self.isSelfOwned = isSelfOwned
		self.createdAt = createdAt
	}
    
    // CodingKeys for all properties (including @Published ones)
    enum CodingKeys: String, CodingKey {
        case id, title, startTime, endTime, location, activityTypeId, note, icon, participantLimit
        case createdAt, creatorUser, invitedUsers
        case participantUsers, chatMessages, participationStatus, isSelfOwned
    }
    
    // Custom decoder
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        location = try container.decodeIfPresent(LocationDTO.self, forKey: .location)
        activityTypeId = try container.decodeIfPresent(UUID.self, forKey: .activityTypeId)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        participantLimit = try container.decodeIfPresent(Int.self, forKey: .participantLimit)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        creatorUser = try container.decode(BaseUserDTO.self, forKey: .creatorUser)
        invitedUsers = try container.decodeIfPresent([BaseUserDTO].self, forKey: .invitedUsers)
        
        // Decode @Published properties to their underlying values
        participantUsers = try container.decodeIfPresent([BaseUserDTO].self, forKey: .participantUsers)
        chatMessages = try container.decodeIfPresent([FullActivityChatMessageDTO].self, forKey: .chatMessages)
        participationStatus = try container.decodeIfPresent(ParticipationStatus.self, forKey: .participationStatus)
        isSelfOwned = try container.decodeIfPresent(Bool.self, forKey: .isSelfOwned)
    }
    
    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(activityTypeId, forKey: .activityTypeId)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encodeIfPresent(participantLimit, forKey: .participantLimit)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encode(creatorUser, forKey: .creatorUser)
        try container.encodeIfPresent(invitedUsers, forKey: .invitedUsers)
        
        // Encode @Published properties
        try container.encodeIfPresent(participantUsers, forKey: .participantUsers)
        try container.encodeIfPresent(chatMessages, forKey: .chatMessages)
        try container.encodeIfPresent(participationStatus, forKey: .participationStatus)
        try container.encodeIfPresent(isSelfOwned, forKey: .isSelfOwned)
    }
}

extension FullFeedActivityDTO {

	static func dateFromTimeString(_ timeString: String) -> Date? {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "h:mm a"  // Parse time in 12-hour format with AM/PM
		dateFormatter.timeZone = .current
		dateFormatter.locale = .current

		// Combine with today's date
		if let parsedTime = dateFormatter.date(from: timeString) {
			let calendar = Calendar.current
			let now = Date()
			return calendar.date(
				bySettingHour: calendar.component(.hour, from: parsedTime),
				minute: calendar.component(.minute, from: parsedTime),
				second: 0,
				of: now)
		}
		return nil
	}

	static let mockDinnerActivity: FullFeedActivityDTO = FullFeedActivityDTO(
		id: UUID(),
		title: "Dinner time!!!!!!",
		startTime: dateFromTimeString("10:00 PM"),
		endTime: dateFromTimeString("11:30 PM"),
		location: LocationDTO(
			id: UUID(), name: "Gather - Place Vanier",
			latitude: 49.26468617023799, longitude: -123.25859833051356),
		note: "let's eat!",
		creatorUser: BaseUserDTO.danielAgapov,
		participantUsers: [
			BaseUserDTO.danielLee,
			BaseUserDTO.haley,
			BaseUserDTO.danielAgapov,
			BaseUserDTO.haley,
		]
	)
    static let mockSelfOwnedActivity: FullFeedActivityDTO = FullFeedActivityDTO(
        id: UUID(),
        title: "Dinner time!!!!!!",
        startTime: dateFromTimeString("10:00 PM"),
        endTime: dateFromTimeString("11:30 PM"),
        location: LocationDTO(
            id: UUID(), name: "Gather - Place Vanier",
            latitude: 49.26468617023799, longitude: -123.25859833051356),
        note: "let's eat!",
        creatorUser: BaseUserDTO.danielAgapov,
        participantUsers: [
            BaseUserDTO.danielLee,
            BaseUserDTO.haley,
            BaseUserDTO.danielAgapov,
            BaseUserDTO.haley,
        ],
        chatMessages: [.mockChat4, .mockChat1, .mockChat2, .mockChat3],
        isSelfOwned: true
    )
    
    static let mockSelfOwnedActivity2: FullFeedActivityDTO = FullFeedActivityDTO(
        id: UUID(),
        title: "Indefinite Hangout",
        startTime: dateFromTimeString("2:00 PM"),
        endTime: nil, // Indefinite activity - no end time
        location: LocationDTO(
            id: UUID(), name: "Central Library",
            latitude: 49.26468617023799, longitude: -123.25859833051356),
        note: "Come hang out whenever you can!",
        creatorUser: BaseUserDTO.danielAgapov,
        participantUsers: [
            BaseUserDTO.danielAgapov,
            BaseUserDTO.danielLee,
        ],
        isSelfOwned: true
    )
    
    // Mock indefinite activity from yesterday - should be filtered out
    static let mockExpiredIndefiniteActivity: FullFeedActivityDTO = FullFeedActivityDTO(
        id: UUID(),
        title: "Yesterday's Indefinite Study Session",
        startTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
        endTime: nil, // Indefinite activity - no end time
        location: LocationDTO(
            id: UUID(), name: "Library",
            latitude: 49.26468617023799, longitude: -123.25859833051356),
        note: "This should be filtered out!",
        creatorUser: BaseUserDTO.danielAgapov,
        participantUsers: [
            BaseUserDTO.danielAgapov,
        ],
        isSelfOwned: true
    )
} 
