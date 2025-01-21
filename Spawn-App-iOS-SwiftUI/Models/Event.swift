//
//  Event.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import Foundation

class Event: Identifiable, Codable {
    var id: UUID
    
    // MARK: Info
    var startTime: Date? // TODO: change to proper time later
    var endTime: Date? // TODO: change to proper time later
    var title: String?
    var location: Location?
    var note: String? // this corresponds to Figma design "my place at 10? I'm cooking guys" note in event
    
    // MARK: Relations
    var creator: User?

    // tech note: I'll be able to check if current user is in an event's partipants to determine which symbol to show in feed
    var participants: [User]?

    // tech note: this will be determined by the `User`'s specified `FriendTag`s on
    // the event, which will populate this `invited` property with the `FriendTag`s'
    // `friends` property (`[User]`), which all have a `baseUser` (`User`) property.
    var invited: [User]?
	var chatMessages: [ChatMessage]?

	init(
		id: UUID,
		title: String? = nil,
		startTime: Date? = nil,
		endTime: Date? = nil,
		location: Location? = nil,
		note: String? = nil,
		creator: User? = User.danielAgapov,
		participants: [User]? = nil,
		chatMessages: [ChatMessage]? = nil,
		invited: [User]? = nil
	) {
		self.id = id
		self.title = title
		self.startTime = startTime
		self.endTime = endTime
		self.location = location
		self.note = note
		self.creator = creator
		self.participants = participants
		self.chatMessages = chatMessages
		self.invited = invited
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
		creator: User.jennifer,
		participants: [
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
			creator: User.danielAgapov,
			participants: [User.danielAgapov, User.jennifer, User.shannon, User.haley, User.danielLee],
			chatMessages: [
				ChatMessage(
					id: UUID(),
					content: "yo guys, wya?",
					timestamp: Date().addingTimeInterval(-30), // 30 seconds ago
					userSender: User.danielAgapov,
					eventId: mockDinnerEvent.id
				),
				ChatMessage(
					id: UUID(),
					content: "I just saw you",
					timestamp: Date().addingTimeInterval(-120), // 2 minutes ago
					userSender: User.danielLee,
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
			creator: User.danielAgapov
		),
		Event(
			id: UUID(),
			title: "Im painting rn lol",
			startTime: Date(),
			endTime: Date(),
			location: Location(id: UUID(), name: "Ross Drive - Wesbrook Mall", latitude: 49.25189587512135, longitude: -123.237051932404),
			creator: User.shannon,
			participants: [User.danielLee]
		),
		Event(
			id: UUID(),
			title: "Grabbing Udon",
			startTime: Date(),
			endTime: Date(),
			location: Location(id: UUID(), name: "Marugame Udon", latitude: 49.28032597998406, longitude: -123.11026665974741),
			creator: User.danielAgapov
		),
		Event(
			id: UUID(),
			title: "Calendar Party",
			startTime: Date(),
			endTime: Date(),
			location: Location(id: UUID(), name: "The Pit - Nest", latitude: 49.26694140754859, longitude: -123.25036565366581),
			creator: User.danielLee
		),
		Event(
			id: UUID(),
			title: "Gym - Leg Day",
			startTime: Date(),
			endTime: Date(),
			location: Location(id: UUID(), name: "UBC Student Recreation Centre", latitude: 49.2687302352351, longitude: -123.24897582888525),
			creator: User.michael
		)
	]
}
