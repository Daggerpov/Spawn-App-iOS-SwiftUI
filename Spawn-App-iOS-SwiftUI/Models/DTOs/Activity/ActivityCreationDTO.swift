//
//  ActivityCreationDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-04.
//

import Foundation

// Should match `ActivityCreationDTO`, as written in back-end:
class ActivityCreationDTO: Identifiable, Codable {
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
	var participantLimit: Int? // nil means unlimited participants

	// MARK: Relations
	var activityTypeId: UUID?
	var creatorUserId: UUID
	var invitedFriendUserIds: [UUID]?

	init(
		id: UUID,
		title: String? = nil,
		startTime: Date? = nil,
		endTime: Date? = nil,
		location: Location? = nil,
		activityTypeId: UUID? = nil,
		note: String? = nil,
		icon: String? = nil,
		participantLimit: Int? = nil,
		creatorUserId: UUID,
		invitedFriendUserIds: [UUID]? = nil
	) {
		self.id = id
		self.title = title
		self.startTime = startTime
		self.endTime = endTime
		self.location = location
		self.activityTypeId = activityTypeId
		self.note = note
		self.icon = icon
		self.participantLimit = participantLimit
		self.creatorUserId = creatorUserId
		self.invitedFriendUserIds = invitedFriendUserIds
	}
} 