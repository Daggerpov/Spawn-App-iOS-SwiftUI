//
//  Event.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel on 11/4/24.
//

import Foundation

struct Event: Identifiable, Codable {
    var id: UUID
    
    // MARK: Info
    var title: String
    var startTime: String // TODO: change to proper time later
    var endTime: String // TODO: change to proper time later
    var location: Location // TODO: change to proper location later
    
    // MARK: Relations
    var creator: User
    
    // tech note: I'll be able to check if current user is in an event's partipants to determine which symbol to show in feed
    var participants: [User]?
    var chatMessages: [ChatMessage]?
}

extension Event {
    static let mockEvents: [Event] = [
        Event(
            id: UUID(),
            title: "Dinner time!!!!!!",
            startTime: "10:00 PM",
            endTime: "11:30 PM",
            location: Location(locationName: "Gather - Place Vanier"),
            creator: User.danielAgapov,
            participants: [User.danielLee]
        ),
        Event(
            id: UUID(),
            title: "wanna run 5k with me?",
            startTime: "04:00 PM",
            endTime: "05:30 PM",
            location: Location(locationName: "Wesbrook Mall"),
            creator: User.danielAgapov
        ),
        Event(
            id: UUID(),
            title: "playing basketball!!!",
            startTime: "06:00 PM",
            endTime: "07:00 PM",
            location: Location(locationName: "UBC Student Recreation Centre"),
            creator: User.danielAgapov
        ),
        Event(
            id: UUID(),
            title: "Im painting rn lol",
            startTime: "10:00 AM",
            endTime: "11:30 AM",
            location: Location(locationName: "Ross Drive - Wesbrook Mall"),
            creator: User.danielAgapov,
            participants: [User.danielLee]
            
        ),
        Event(
            id: UUID(),
            title: "Grabbing Udon",
            startTime: "12:00 PM",
            endTime: "02:30 PM",
            location: Location(locationName: "Marugame Udon"),
            creator: User.danielAgapov
        ),
        Event(
            id: UUID(),
            title: "Calendar Party",
            startTime: "11:00 PM",
            endTime: "02:30 AM",
            location: Location(locationName: "The Pit - Nest"),
            creator: User.danielAgapov
        ),
        Event(
            id: UUID(),
            title: "Gym - Leg Day",
            startTime: "10:00 AM",
            endTime: "11:30 AM",
            location: Location(locationName: "UBC Student Recreation Centre"),
            creator: User.danielAgapov
        )
    ]
}
