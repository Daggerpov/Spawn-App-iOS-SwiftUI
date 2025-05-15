//
//  EventCreationDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-04.
//

import Foundation

// Should match `EventCreationDTO`, as written in back-end:
class EventCreationDTO: Identifiable, Codable {
	var id: UUID
	var title: String?

	// MARK: Info
	var startTime: Date?
	var endTime: Date?
	var location: Location?
	var note: String?
	/* The icon is stored as a Unicode emoji character string (e.g. "⭐️", "🎉", "🏀").
	   This is the literal emoji character, not a shortcode or description.
	   It's rendered directly in the UI and stored as a single UTF-8 string in the database. */
	var icon: String?
	var category: EventCategory = .general

	// MARK: Relations
	var creatorUserId: UUID
	var invitedFriendTagIds: [UUID]?
	var invitedFriendUserIds: [UUID]?

	init(
		id: UUID,
		title: String? = nil,
		startTime: Date? = nil,
		endTime: Date? = nil,
		location: Location? = nil,
		note: String? = nil,
		icon: String? = nil,
		category: EventCategory = .general,
		creatorUserId: UUID,
		invitedFriendTagIds: [UUID]? = nil,
		invitedFriendUserIds: [UUID]? = nil
	) {
		self.id = id
		self.title = title
		self.startTime = startTime
		self.endTime = endTime
		self.location = location
		self.note = note
		self.icon = icon
		self.category = category
		self.creatorUserId = creatorUserId
		self.invitedFriendTagIds = invitedFriendTagIds
		self.invitedFriendUserIds = invitedFriendUserIds
	}
}
