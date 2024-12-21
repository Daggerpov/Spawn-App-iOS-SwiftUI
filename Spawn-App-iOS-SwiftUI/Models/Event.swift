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
    var title: String
    var startTime: String? // TODO: change to proper time later
    var endTime: String? // TODO: change to proper time later
    var location: Location? 
    var note: String? // this corresponds to Figma design "my place at 10? I'm cooking guys" note in event
    
    // MARK: Relations
    var creator: User
    
    // tech note: I'll be able to check if current user is in an event's partipants to determine which symbol to show in feed
    var participants: [User]?

    // tech note: this will be determined by the `User`'s specified `FriendTag`s on
    // the event, which will populate this `invited` property with the `FriendTag`s'
    // `friends` property (`[User]`), which all have a `baseUser` (`User`) property.
    var invited: [User]?
	var chatMessages: [ChatMessage]?

	init(
		id: UUID,
		title: String,
		startTime: String? = nil,
		endTime: String? = nil,
		location: Location? = nil,
		note: String? = nil,
		creator: User,
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
    static let mockEvents: [Event] = [
        Event(
            id: UUID(),
            title: "Dinner time!!!!!!",
            startTime: "10:00 PM",
            endTime: "11:30 PM",
            location: Location(id: UUID(), name: "Gather - Place Vanier", latitude: 49.26468617023799, longitude: -123.25859833051356),
            note: "let's eat!",
            creator: User.jennifer,
            participants: [
                User.danielLee,
                User.haley,
                User.jennifer,
                User.michael
            ]
        ),
        Event(
            id: UUID(),
            title: "wanna run 5k with me?",
            startTime: "04:00 PM",
            location: Location(id: UUID(), name: "Wesbrook Mall", latitude: 49.25997722657244, longitude: -123.23986523529379),
            creator: User.danielAgapov,
            participants: [User.danielAgapov, User.jennifer, User.shannon, User.haley, User.danielLee],
            chatMessages: [
                ChatMessage(
                    id: UUID(),
                    message: "yo guys, wya?",
                    timestamp: "2 minutes ago",
                    user: User.danielAgapov
                ),
                ChatMessage(id: UUID(), message: "I just saw you", timestamp: "30 seconds ago", user: User.danielLee)
            ]
        ),
        Event(
            id: UUID(),
            title: "playing basketball!!!",
            endTime: "07:00 PM",
            location: Location(id: UUID(), name: "UBC Student Recreation Centre", latitude: 49.2687302352351, longitude: -123.24897582888525),
            note: "let's play basketball!",
            creator: User.danielAgapov
        ),
        Event(
            id: UUID(),
            title: "Im painting rn lol",
            startTime: "10:00 AM",
            endTime: "11:30 AM",
            location: Location(id: UUID(), name: "Ross Drive - Wesbrook Mall", latitude: 49.25189587512135, longitude: -123.237051932404),
            creator: User.shannon,
            participants: [User.danielLee]
            
        ),
        // commenting this one out, since its location messes with the map zoom level (zooms it way out)
        // TODO: we should find a system to handle this better
//        Event(
//            id: UUID(),
//            title: "Grabbing Udon",
//            startTime: "12:00 PM",
//            endTime: "02:30 PM",
//            location: Location(id: UUID(), name: "Marugame Udon", latitude: 49.28032597998406, longitude: -123.11026665974741),
//            creator: User.danielAgapov
//        ),
        Event(
            id: UUID(),
            title: "Calendar Party",
            startTime: "11:00 PM",
            endTime: "02:30 AM",
            location: Location(id: UUID(), name: "The Pit - Nest", latitude: 49.26694140754859, longitude: -123.25036565366581),
            creator: User.danielLee
        ),
        Event(
            id: UUID(),
            title: "Gym - Leg Day",
            startTime: "10:00 AM",
            endTime: "11:30 AM",
            location: Location(id: UUID(), name: "UBC Student Recreation Centre", latitude: 49.2687302352351, longitude: -123.24897582888525),
            creator: User.michael
        )
    ]
}
