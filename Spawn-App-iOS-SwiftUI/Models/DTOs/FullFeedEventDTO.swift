//
//  FullFeedEventDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-27.
//

/// updated to match back-end's `FullFeedEventDTO`, after Shane's PR here: https://github.com/Daggerpov/Spawn-App-Back-End/pull/222/files

import Foundation

class FullFeedEventDTO: Identifiable, Codable {
	var id: UUID
	var title: String?

	// MARK: Info
	var startTime: Date?
	var endTime: Date?
	var location: Location?
	var note: String?  // this corresponds to Figma design "my place at 10? I'm cooking guys" note in event

	// MARK: Relations
	var creatorUser: BaseUserDTO

	// tech note: I'll be able to check if current user is in an event's partipants to determine which symbol to show in feed
	var participantUsers: [BaseUserDTO]?

	// tech note: this will be determined by the `User`'s specified `FriendTag`s on
	// the event, which will populate this `invited` property with the `FriendTag`s'
	// `friends` property (`[User]`), which all have a `baseUser` (`User`) property.
	var invitedUsers: [BaseUserDTO]?
	var chatMessages: [FullEventChatMessageDTO]?
	var eventFriendTagColorHexCodeForRequestingUser: String?
	var participationStatus: ParticipationStatus?

	init(
		id: UUID,
		title: String? = nil,
		startTime: Date? = nil,
		endTime: Date? = nil,
		location: Location? = nil,
		note: String? = nil,
		creatorUser: BaseUserDTO,
		participantUsers: [BaseUserDTO]? = nil,
		invitedUsers: [BaseUserDTO]? = nil,
		chatMessages: [FullEventChatMessageDTO]? = nil,
		eventFriendTagColorHexCodeForRequestingUser: String? = nil,
		participationStatus: ParticipationStatus? = nil
	) {
		self.id = id
		self.title = title
		self.startTime = startTime
		self.endTime = endTime
		self.location = location
		self.note = note
		self.creatorUser = creatorUser
		self.participantUsers = participantUsers
		self.invitedUsers = invitedUsers
		self.chatMessages = chatMessages
		self.eventFriendTagColorHexCodeForRequestingUser =
		eventFriendTagColorHexCodeForRequestingUser
		self.participationStatus = participationStatus
	}
}

extension FullFeedEventDTO {

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

	static let mockDinnerEvent: FullFeedEventDTO = FullFeedEventDTO(
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
}
