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
	var title: String

	// MARK: Info
	var startTime: Date?
	var endTime: Date?
	var location: Location?
	var note: String?

	// MARK: Relations
	var creatorUserId: UUID
	var invitedFriendTagIds: [UUID]?
	var invitedFriendUserIds: [UUID]?

	init(
		id: UUID,
		title: String,
		startTime: Date? = nil,
		endTime: Date? = nil,
		location: Location? = nil,
		note: String? = nil,
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
		self.creatorUserId = creatorUserId
		self.invitedFriendTagIds = invitedFriendTagIds
		self.invitedFriendUserIds = invitedFriendUserIds
	}
}
