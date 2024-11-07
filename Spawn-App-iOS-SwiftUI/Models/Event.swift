//
//  Event.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel on 11/4/24.
//

import Foundation

struct Event: Identifiable, Codable {
    var id: UUID
    var title: String
    var startTime: String // TODO: change to proper time later
    var endTime: String // TODO: change to proper time later
    var location: String // TODO: change to proper location later
    var symbolName: String // TODO: maybe change later?
}

extension Event {
    static let mockEvents: [Event] = [
        Event(
            id: UUID(),
            title: "Dinner time!!!!!!",
            startTime: "10:00 PM",
            endTime: "11:30 PM",
            location: "Gather - Place Vanier",
            symbolName: "checkmark"
        ),
        Event(
            id: UUID(),
            title: "wanna run 5k with me?",
            startTime: "04:00 PM",
            endTime: "05:30 PM",
            location: "Wesbrook Mall",
            symbolName: "star.fill"
        ),
        Event(
            id: UUID(),
            title: "playing basketball!!!",
            startTime: "06:00 PM",
            endTime: "07:00 PM",
            location: "UBC Student Recreation Centre",
            symbolName: "star.fill"
        ),
        Event(
            id: UUID(),
            title: "Im painting rn lol",
            startTime: "10:00 AM",
            endTime: "11:30 AM",
            location: "Ross Drive - Wesbrook Mall",
            symbolName: "star.fill"
        ),
        Event(
            id: UUID(),
            title: "Grabbing Udon",
            startTime: "12:00 PM",
            endTime: "02:30 PM",
            location: "Marugame Udon",
            symbolName: "star.fill"
        ),
        Event(
            id: UUID(),
            title: "Calendar Party",
            startTime: "11:00 PM",
            endTime: "02:30 AM",
            location: "The Pit - Nest",
            symbolName: "star.fill"
        ),
        Event(
            id: UUID(),
            title: "Gym - Leg Day",
            startTime: "10:00 AM",
            endTime: "11:30 AM",
            location: "UBC Student Recreation Centre",
            symbolName: "star.fill"
        )
    ]
}
