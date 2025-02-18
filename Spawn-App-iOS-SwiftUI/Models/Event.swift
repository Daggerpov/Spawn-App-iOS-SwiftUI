//
//  Event.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import Foundation

// Should match `FullFeedEventDTO`, as written in back-end:
class Event: Identifiable, Codable {
    var id: UUID
	var title: String?

    // MARK: Info
    var startTime: Date? // TODO: change to proper time later
    var endTime: Date? // TODO: change to proper time later
    var location: Location?
    var note: String? // this corresponds to Figma design "my place at 10? I'm cooking guys" note in event
    
    // MARK: Relations
    var creatorUser: User?

    // tech note: I'll be able to check if current user is in an event's partipants to determine which symbol to show in feed
    var participantUsers: [User]?

    // tech note: this will be determined by the `User`'s specified `FriendTag`s on
    // the event, which will populate this `invited` property with the `FriendTag`s'
    // `friends` property (`[User]`), which all have a `baseUser` (`User`) property.
    var invitedUsers: [User]?
	var chatMessages: [ChatMessage]?
	var eventFriendTagColorHexCodeForRequestingUser: String?
	var participationStatus: ParticipationStatus?

	init(
		id: UUID,
		title: String? = nil,
		startTime: Date? = nil,
		endTime: Date? = nil,
		location: Location? = nil,
		note: String? = nil,
		creatorUser: User? = User.danielAgapov,
		participantUsers: [User]? = nil,
		invitedUsers: [User]? = nil,
		chatMessages: [ChatMessage]? = nil,
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
		self.eventFriendTagColorHexCodeForRequestingUser = eventFriendTagColorHexCodeForRequestingUser
		self.participationStatus = participationStatus
	}

	private enum CodingKeys: String, CodingKey {
		case id, title, startTime, endTime, location, note, creatorUser, participantUsers, invitedUsers, chatMessages, eventFriendTagColorHexCodeForRequestingUser, participationStatus
	}

	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		// Decode UUID and optional fields
		self.id = try container.decode(UUID.self, forKey: .id)
		self.title = try container.decodeIfPresent(String.self, forKey: .title)
		self.note = try container.decodeIfPresent(String.self, forKey: .note)
		self.eventFriendTagColorHexCodeForRequestingUser = try container.decodeIfPresent(String.self, forKey: .eventFriendTagColorHexCodeForRequestingUser)

		// Custom decoding for startTime and endTime (handling OffsetDateTime to Date)
		let dateFormatter = ISO8601DateFormatter()
		self.startTime = try container.decodeIfPresent(String.self, forKey: .startTime).flatMap { dateFormatter.date(from: $0) }
		self.endTime = try container.decodeIfPresent(String.self, forKey: .endTime).flatMap { dateFormatter.date(from: $0) }

		// Handle the rest of the nested objects
		self.creatorUser = try container.decodeIfPresent(User.self, forKey: .creatorUser)
		self.participantUsers = try container.decodeIfPresent([User].self, forKey: .participantUsers)
		self.invitedUsers = try container.decodeIfPresent([User].self, forKey: .invitedUsers)
		self.chatMessages = try container.decodeIfPresent([ChatMessage].self, forKey: .chatMessages)

		// Participation status might need a specific decoder as well
		self.participationStatus = try container.decodeIfPresent(ParticipationStatus.self, forKey: .participationStatus)
	}
}

extension Event {

	static func dateFromTimeString(_ timeString: String) -> Date? {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "h:mm a" // Parse time in 12-hour format with AM/PM
		dateFormatter.timeZone = .current
		dateFormatter.locale = .current

		// Combine with today's date
		if let parsedTime = dateFormatter.date(from: timeString) {
			let calendar = Calendar.current
			let now = Date()
			return calendar.date(bySettingHour: calendar.component(.hour, from: parsedTime),
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
		location: Location(id: UUID(), name: "Gather - Place Vanier", latitude: 49.26468617023799, longitude: -123.25859833051356),
		note: "let's eat!",
		creatorUser: User.jennifer,
		participantUsers: [
			User.danielLee,
			User.haley,
			User.jennifer,
			User.michael
		]
	)

	static let mockEvents: [Event] = [
		mockDinnerEvent,
		Event(
			id: UUID(),
			title: "wanna run 5k with me?",
			startTime: Date(),
			location: Location(id: UUID(), name: "Wesbrook Mall", latitude: 49.25997722657244, longitude: -123.23986523529379),
			creatorUser: User.danielAgapov,
			participantUsers: [User.danielAgapov, User.jennifer, User.shannon, User.haley, User.danielLee],
			chatMessages: [
				ChatMessage(
					id: UUID(),
					content: "yo guys, wya?",
					timestamp: Date().addingTimeInterval(-30), // 30 seconds ago
					senderUser: User.danielAgapov,
					eventId: mockDinnerEvent.id
				),
				ChatMessage(
					id: UUID(),
					content: "I just saw you",
					timestamp: Date().addingTimeInterval(-120), // 2 minutes ago
					senderUser: User.danielLee,
					eventId: mockDinnerEvent.id
				)
			]
		),
		Event(
			id: UUID(),
			title: "playing basketball!!!",
			endTime: Date(),
			location: Location(id: UUID(), name: "UBC Student Recreation Centre", latitude: 49.2687302352351, longitude: -123.24897582888525),
			note: "let's play basketball!",
			creatorUser: User.danielAgapov
		),
		Event(
			id: UUID(),
			title: "Im painting rn lol",
			startTime: Date(),
			endTime: Date(),
			location: Location(id: UUID(), name: "Ross Drive - Wesbrook Mall", latitude: 49.25189587512135, longitude: -123.237051932404),
			creatorUser: User.shannon,
			participantUsers: [User.danielLee]
		),
		Event(
			id: UUID(),
			title: "Grabbing Udon",
			startTime: Date(),
			endTime: Date(),
			location: Location(id: UUID(), name: "Marugame Udon", latitude: 49.28032597998406, longitude: -123.11026665974741),
			creatorUser: User.danielAgapov
		),
		Event(
			id: UUID(),
			title: "Calendar Party",
			startTime: Date(),
			endTime: Date(),
			location: Location(id: UUID(), name: "The Pit - Nest", latitude: 49.26694140754859, longitude: -123.25036565366581),
			creatorUser: User.danielLee
		),
		Event(
			id: UUID(),
			title: "Gym - Leg Day",
			startTime: Date(),
			endTime: Date(),
			location: Location(id: UUID(), name: "UBC Student Recreation Centre", latitude: 49.2687302352351, longitude: -123.24897582888525),
			creatorUser: User.michael
		)
	]
}
