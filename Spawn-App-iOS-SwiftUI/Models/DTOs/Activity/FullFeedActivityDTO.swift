//
//  FullFeedActivityDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-27.
//

import Foundation

class FullFeedActivityDTO: Identifiable, Codable, Equatable {
	static func == (lhs: FullFeedActivityDTO, rhs: FullFeedActivityDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var title: String?

	// MARK: Info
	var startTime: Date?
	var endTime: Date?
	var location: Location?
	var note: String?  // this corresponds to Figma design "my place at 10? I'm cooking guys" note in activity
	/* The icon is stored as a Unicode emoji character string (e.g. "⭐️", "🎉", "🏀").
	   This is the literal emoji character, not a shortcode or description.
	   It's rendered directly in the UI and stored as a single UTF-8 string in the database. */
	var icon: String?
	var category: ActivityCategory = .general
	var createdAt: Date?

	// MARK: Relations
	var creatorUser: BaseUserDTO

	// tech note: I'll be able to check if current user is in an activity's partipants to determine which symbol to show in feed
	var participantUsers: [BaseUserDTO]?
	var invitedUsers: [BaseUserDTO]?
	var chatMessages: [FullActivityChatMessageDTO]?
	var participationStatus: ParticipationStatus?
	var isSelfOwned: Bool?

	init(
		id: UUID,
		title: String? = nil,
		startTime: Date? = nil,
		endTime: Date? = nil,
		location: Location? = nil,
		note: String? = nil,
		icon: String? = nil,
		category: ActivityCategory = .general,
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
		self.note = note
		self.icon = icon
		self.category = category
		self.creatorUser = creatorUser
		self.participantUsers = participantUsers
		self.invitedUsers = invitedUsers
		self.chatMessages = chatMessages
		self.participationStatus = participationStatus
		self.isSelfOwned = isSelfOwned
		self.createdAt = createdAt
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
		location: Location(
			id: UUID(), name: "Gather - Place Vanier",
			latitude: 49.26468617023799, longitude: -123.25859833051356),
		note: "let's eat!",
		creatorUser: BaseUserDTO.jennifer,
		participantUsers: [
			BaseUserDTO.danielLee,
			BaseUserDTO.haley,
			BaseUserDTO.jennifer,
			BaseUserDTO.michael,
		]
	)
    static let mockSelfOwnedActivity: FullFeedActivityDTO = FullFeedActivityDTO(
        id: UUID(),
        title: "Dinner time!!!!!!",
        startTime: dateFromTimeString("10:00 PM"),
        endTime: dateFromTimeString("11:30 PM"),
        location: Location(
            id: UUID(), name: "Gather - Place Vanier",
            latitude: 49.26468617023799, longitude: -123.25859833051356),
        note: "let's eat!",
        creatorUser: BaseUserDTO.jennifer,
        participantUsers: [
            BaseUserDTO.danielLee,
            BaseUserDTO.haley,
            BaseUserDTO.jennifer,
            BaseUserDTO.michael,
        ],
        isSelfOwned: true
    )
    static let mockSelfOwnedActivity2: FullFeedActivityDTO = FullFeedActivityDTO(
        id: UUID(),
        title: "Dinner time!!!!!!",
        startTime: dateFromTimeString("10:00 PM"),
        endTime: dateFromTimeString("11:30 PM"),
        location: Location(
            id: UUID(), name: "Gather - Place Vanier",
            latitude: 49.26468617023799, longitude: -123.25859833051356),
        note: "let's eat!",
        creatorUser: BaseUserDTO.jennifer,
        participantUsers: [],
        isSelfOwned: true
    )
} 