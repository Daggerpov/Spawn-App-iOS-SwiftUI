//
//  Activity.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import Foundation

class Activity: Identifiable, Codable {
	var id: UUID
	var title: String?

	// MARK: Info
	var startTime: Date?
	var endTime: Date?
	var location: Location?
	var note: String?  // this corresponds to Figma design "my place at 10? I'm cooking guys" note in activity
	var createdAt: Date?

	// MARK: Relations
	var activityTypeId: UUID?
	var creatorUser: UserDTO?

	// tech note: I'll be able to check if current user is in an activity's partipants to determine which symbol to show in feed
	var participantUsers: [UserDTO]?
	var invitedUsers: [UserDTO]?
	var chatMessages: [FullActivityChatMessageDTO]?
	var participationStatus: ParticipationStatus?

	init(
		id: UUID,
		title: String? = nil,
		startTime: Date? = nil,
		endTime: Date? = nil,
		location: Location? = nil,
		activityTypeId: UUID? = nil,
		note: String? = nil,
		creatorUser: UserDTO? = UserDTO.danielAgapov,
		participantUsers: [UserDTO]? = nil,
		invitedUsers: [UserDTO]? = nil,
		chatMessages: [FullActivityChatMessageDTO]? = nil,
		participationStatus: ParticipationStatus? = nil,
		createdAt: Date? = nil
	) {
		self.id = id
		self.title = title
		self.startTime = startTime
		self.endTime = endTime
		self.location = location
		self.activityTypeId = activityTypeId
		self.note = note
		self.creatorUser = creatorUser
		self.participantUsers = participantUsers
		self.invitedUsers = invitedUsers
		self.chatMessages = chatMessages
		self.participationStatus = participationStatus
		self.createdAt = createdAt
	}
}

extension Activity {

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

	static let mockDinnerActivity: Activity = Activity(
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

	static let mockActivities: [Activity] = [
		mockDinnerActivity,
		Activity(
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
				FullActivityChatMessageDTO(
					id: UUID(),
					content: "yo guys, wya?",
					timestamp: Date().addingTimeInterval(-30),  // 30 seconds ago
					senderUser: BaseUserDTO.danielAgapov,
					activityId: mockDinnerActivity.id
				),
				FullActivityChatMessageDTO(
					id: UUID(),
					content: "I just saw you",
					timestamp: Date().addingTimeInterval(-120),  // 2 minutes ago
					senderUser: BaseUserDTO.danielLee,
					activityId: mockDinnerActivity.id
				),
			]
		),
		Activity(
			id: UUID(),
			title: "playing basketball!!!",
			endTime: Date(),
			location: Location(
				id: UUID(), name: "UBC Student Recreation Centre",
				latitude: 49.2687302352351, longitude: -123.24897582888525),
			note: "let's play basketball!",
			creatorUser: UserDTO.danielAgapov
		),
		Activity(
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
		Activity(
			id: UUID(),
			title: "Grabbing Udon",
			startTime: Date(),
			endTime: Date(),
			location: Location(
				id: UUID(), name: "Marugame Udon", latitude: 49.28032597998406,
				longitude: -123.11026665974741),
			creatorUser: UserDTO.danielAgapov
		),
		Activity(
			id: UUID(),
			title: "Calendar Party",
			startTime: Date(),
			endTime: Date(),
			location: Location(
				id: UUID(), name: "The Pit - Nest", latitude: 49.26694140754859,
				longitude: -123.25036565366581),
			creatorUser: UserDTO.danielLee
		),
		Activity(
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