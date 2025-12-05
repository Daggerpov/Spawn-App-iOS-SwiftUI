//
//  ActivityDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-21.
//

import Foundation

/// Unified ActivityDTO that matches the back-end ActivityDTO structure.
/// Replaces both ActivityCreationDTO and handles both creation and updates.
/// Uses @unchecked Sendable because it's a class with mutable state that needs to cross
/// async boundaries. The mutable state is only modified on MainActor in practice.
class ActivityDTO: Identifiable, Codable, Equatable, ObservableObject, @unchecked Sendable {
	static func == (lhs: ActivityDTO, rhs: ActivityDTO) -> Bool {
		return lhs.id == rhs.id
	}

	// Properties from AbstractActivityDTO (base class in back-end)
	var id: UUID
	var title: String?
	var startTime: Date?
	var endTime: Date?
	var note: String?
	var icon: String?
	var participantLimit: Int?  // nil means unlimited participants
	var createdAt: Date?

	// Properties from ActivityDTO (derived class in back-end)
	var location: LocationDTO?
	var activityTypeId: UUID?
	var creatorUserId: UUID?
	var participantUserIds: [UUID]?
	var invitedUserIds: [UUID]?
	var chatMessageIds: [UUID]?
	var clientTimezone: String?  // Timezone of the client creating the activity (e.g., "America/New_York")

	init(
		id: UUID,
		title: String? = nil,
		startTime: Date? = nil,
		endTime: Date? = nil,
		note: String? = nil,
		icon: String? = nil,
		participantLimit: Int? = nil,
		createdAt: Date? = nil,
		location: LocationDTO? = nil,
		activityTypeId: UUID? = nil,
		creatorUserId: UUID? = nil,
		participantUserIds: [UUID]? = nil,
		invitedUserIds: [UUID]? = nil,
		chatMessageIds: [UUID]? = nil,
		clientTimezone: String? = nil
	) {
		self.id = id
		self.title = title
		self.startTime = startTime
		self.endTime = endTime
		self.note = note
		self.icon = icon
		self.participantLimit = participantLimit
		self.createdAt = createdAt
		self.location = location
		self.activityTypeId = activityTypeId
		self.creatorUserId = creatorUserId
		self.participantUserIds = participantUserIds
		self.invitedUserIds = invitedUserIds
		self.chatMessageIds = chatMessageIds
		self.clientTimezone = clientTimezone
	}

	// CodingKeys for proper JSON serialization/deserialization
	enum CodingKeys: String, CodingKey {
		case id, title, startTime, endTime, note, icon, participantLimit, createdAt
		case location, activityTypeId, creatorUserId, participantUserIds, invitedUserIds, chatMessageIds, clientTimezone
	}

	// Custom decoder to handle the JSON structure from back-end
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		id = try container.decode(UUID.self, forKey: .id)
		title = try container.decodeIfPresent(String.self, forKey: .title)
		startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
		endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
		note = try container.decodeIfPresent(String.self, forKey: .note)
		icon = try container.decodeIfPresent(String.self, forKey: .icon)
		participantLimit = try container.decodeIfPresent(Int.self, forKey: .participantLimit)
		createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
		location = try container.decodeIfPresent(LocationDTO.self, forKey: .location)
		activityTypeId = try container.decodeIfPresent(UUID.self, forKey: .activityTypeId)
		creatorUserId = try container.decodeIfPresent(UUID.self, forKey: .creatorUserId)
		participantUserIds = try container.decodeIfPresent([UUID].self, forKey: .participantUserIds)
		invitedUserIds = try container.decodeIfPresent([UUID].self, forKey: .invitedUserIds)
		chatMessageIds = try container.decodeIfPresent([UUID].self, forKey: .chatMessageIds)
		clientTimezone = try container.decodeIfPresent(String.self, forKey: .clientTimezone)
	}

	// Custom encoder to ensure proper JSON structure for back-end
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		try container.encode(id, forKey: .id)
		try container.encodeIfPresent(title, forKey: .title)
		try container.encodeIfPresent(startTime, forKey: .startTime)
		try container.encodeIfPresent(endTime, forKey: .endTime)
		try container.encodeIfPresent(note, forKey: .note)
		try container.encodeIfPresent(icon, forKey: .icon)
		try container.encodeIfPresent(participantLimit, forKey: .participantLimit)
		try container.encodeIfPresent(createdAt, forKey: .createdAt)
		try container.encodeIfPresent(location, forKey: .location)
		try container.encodeIfPresent(activityTypeId, forKey: .activityTypeId)
		try container.encodeIfPresent(creatorUserId, forKey: .creatorUserId)
		try container.encodeIfPresent(participantUserIds, forKey: .participantUserIds)
		try container.encodeIfPresent(invitedUserIds, forKey: .invitedUserIds)
		try container.encodeIfPresent(chatMessageIds, forKey: .chatMessageIds)
		try container.encodeIfPresent(clientTimezone, forKey: .clientTimezone)
	}
}

// MARK: - Convenience methods for backward compatibility

extension ActivityDTO {
	// For backward compatibility with ActivityCreationDTO usage
	var invitedFriendUserIds: [UUID]? {
		get { invitedUserIds }
		set { invitedUserIds = newValue }
	}
}
