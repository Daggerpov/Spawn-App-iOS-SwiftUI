//
//  Event.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import Foundation

class Event: Identifiable, Codable {
	var id: UUID
	var title: String?

	// MARK: Info
	var startTime: Date?
	var endTime: Date?
	var location: Location?
	var note: String?  // this corresponds to Figma design "my place at 10? I'm cooking guys" note in event

	// MARK: Relations
	var creatorUser: UserDTO?

	// tech note: I'll be able to check if current user is in an event's partipants to determine which symbol to show in feed
	var participantUsers: [UserDTO]?
	var invitedUsers: [UserDTO]?
	var chatMessages: [FullEventChatMessageDTO]?
	var participationStatus: ParticipationStatus?

	init(
		id: UUID,
		title: String? = nil,
		startTime: Date? = nil,
		endTime: Date? = nil,
		location: Location? = nil,
		note: String? = nil,
		creatorUser: UserDTO? = UserDTO.danielAgapov,
		participantUsers: [UserDTO]? = nil,
		invitedUsers: [UserDTO]? = nil,
		chatMessages: [FullEventChatMessageDTO]? = nil,
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
		self.participationStatus = participationStatus
	}
}

extension Event {

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

	static let mockDinnerEvent: Event = Event(
		id: UUID(),
		title: "Dinner time!!!!!!",
		startTime: dateFromTimeString("10:00 PM"),
		endTime: dateFromTimeString("11:30 PM"),
		location: Location(
			id: UUID(), name: "Gather - Place Vanier",
			latitude: 49.26468617023799, longitude: -123.25859833051356),
		note: "let's eat!",
		creatorUser: UserDTO.jennifer,
		participantUsers: [
			UserDTO.danielLee,
			UserDTO.haley,
			UserDTO.jennifer,
			UserDTO.michael,
		]
	)

	static let mockEvents: [Event] = [
		mockDinnerEvent,
		Event(
			id: UUID(),
			title: "wanna run 5k with me?",
			startTime: Date(),
			location: Location(
				id: UUID(), name: "Wesbrook Mall", latitude: 49.25997722657244,
				longitude: -123.23986523529379),
			creatorUser: UserDTO.danielAgapov,
			participantUsers: [
				UserDTO.danielAgapov, UserDTO.jennifer, UserDTO.shannon, UserDTO.haley,
				UserDTO.danielLee,
			],
			chatMessages: [
				FullEventChatMessageDTO(
					id: UUID(),
					content: "yo guys, wya?",
					timestamp: Date().addingTimeInterval(-30),  // 30 seconds ago
					senderUser: BaseUserDTO.danielAgapov,
					eventId: mockDinnerEvent.id
				),
				FullEventChatMessageDTO(
					id: UUID(),
					content: "I just saw you",
					timestamp: Date().addingTimeInterval(-120),  // 2 minutes ago
					senderUser: BaseUserDTO.danielLee,
					eventId: mockDinnerEvent.id
				),
			]
		),
		Event(
			id: UUID(),
			title: "playing basketball!!!",
			endTime: Date(),
			location: Location(
				id: UUID(), name: "UBC Student Recreation Centre",
				latitude: 49.2687302352351, longitude: -123.24897582888525),
			note: "let's play basketball!",
			creatorUser: UserDTO.danielAgapov
		),
		Event(
			id: UUID(),
			title: "Im painting rn lol",
			startTime: Date(),
			endTime: Date(),
			location: Location(
				id: UUID(), name: "Ross Drive - Wesbrook Mall",
				latitude: 49.25189587512135, longitude: -123.237051932404),
			creatorUser: UserDTO.shannon,
			participantUsers: [UserDTO.danielLee]
		),
		Event(
			id: UUID(),
			title: "Grabbing Udon",
			startTime: Date(),
			endTime: Date(),
			location: Location(
				id: UUID(), name: "Marugame Udon", latitude: 49.28032597998406,
				longitude: -123.11026665974741),
			creatorUser: UserDTO.danielAgapov
		),
		Event(
			id: UUID(),
			title: "Calendar Party",
			startTime: Date(),
			endTime: Date(),
			location: Location(
				id: UUID(), name: "The Pit - Nest", latitude: 49.26694140754859,
				longitude: -123.25036565366581),
			creatorUser: UserDTO.danielLee
		),
		Event(
			id: UUID(),
			title: "Gym - Leg Day",
			startTime: Date(),
			endTime: Date(),
			location: Location(
				id: UUID(), name: "UBC Student Recreation Centre",
				latitude: 49.2687302352351, longitude: -123.24897582888525),
			creatorUser: UserDTO.michael
		),
	]
}
