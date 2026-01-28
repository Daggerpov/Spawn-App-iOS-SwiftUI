//
//  ProfileActivityDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-06-15.
//

import Foundation

/// DTO specifically for profile view activities that includes whether the activity is past or upcoming.
/// This matches the backend ProfileActivityDTO structure which extends AbstractActivityDTO
/// (NOT FullFeedActivityDTO - which has chatMessages instead of chatMessageIds).
final class ProfileActivityDTO: Identifiable, Codable, Equatable, ObservableObject, @unchecked Sendable {
	static func == (lhs: ProfileActivityDTO, rhs: ProfileActivityDTO) -> Bool {
		return lhs.id == rhs.id
	}

	// Properties from AbstractActivityDTO (base class in back-end)
	var id: UUID
	var title: String?
	var startTime: Date?
	var endTime: Date?
	var note: String?
	var icon: String?
	var participantLimit: Int?
	var createdAt: Date?
	var isExpired: Bool?
	var clientTimezone: String?

	// Properties specific to ProfileActivityDTO
	var location: LocationDTO?
	var creatorUser: BaseUserDTO
	var participantUsers: [BaseUserDTO]?
	var invitedUsers: [BaseUserDTO]?
	var chatMessageIds: [UUID]?
	var isPastActivity: Bool

	init(
		id: UUID,
		title: String? = nil,
		startTime: Date? = nil,
		endTime: Date? = nil,
		note: String? = nil,
		icon: String? = nil,
		participantLimit: Int? = nil,
		createdAt: Date? = nil,
		isExpired: Bool? = nil,
		clientTimezone: String? = nil,
		location: LocationDTO? = nil,
		creatorUser: BaseUserDTO,
		participantUsers: [BaseUserDTO]? = nil,
		invitedUsers: [BaseUserDTO]? = nil,
		chatMessageIds: [UUID]? = nil,
		isPastActivity: Bool = false
	) {
		self.id = id
		self.title = title
		self.startTime = startTime
		self.endTime = endTime
		self.note = note
		self.icon = icon
		self.participantLimit = participantLimit
		self.createdAt = createdAt
		self.isExpired = isExpired
		self.clientTimezone = clientTimezone
		self.location = location
		self.creatorUser = creatorUser
		self.participantUsers = participantUsers
		self.invitedUsers = invitedUsers
		self.chatMessageIds = chatMessageIds
		self.isPastActivity = isPastActivity
	}

	// CodingKeys for all properties
	// Note: "pastActivity" is a fallback key because Lombok with Jackson may serialize
	// "isPastActivity" as "pastActivity" unless @JsonProperty is used on the backend.
	enum CodingKeys: String, CodingKey {
		case id, title, startTime, endTime, note, icon, participantLimit, createdAt
		case isExpired, clientTimezone, location, creatorUser, participantUsers
		case invitedUsers, chatMessageIds, isPastActivity, pastActivity
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
		isExpired = try container.decodeIfPresent(Bool.self, forKey: .isExpired)
		clientTimezone = try container.decodeIfPresent(String.self, forKey: .clientTimezone)
		location = try container.decodeIfPresent(LocationDTO.self, forKey: .location)
		creatorUser = try container.decode(BaseUserDTO.self, forKey: .creatorUser)
		participantUsers = try container.decodeIfPresent([BaseUserDTO].self, forKey: .participantUsers)
		invitedUsers = try container.decodeIfPresent([BaseUserDTO].self, forKey: .invitedUsers)
		chatMessageIds = try container.decodeIfPresent([UUID].self, forKey: .chatMessageIds)

		// Handle both "isPastActivity" (correct) and "pastActivity" (Lombok default without @JsonProperty)
		if let isPast = try container.decodeIfPresent(Bool.self, forKey: .isPastActivity) {
			isPastActivity = isPast
		} else if let isPast = try container.decodeIfPresent(Bool.self, forKey: .pastActivity) {
			isPastActivity = isPast
		} else {
			// Fallback: determine from isExpired or default to false
			isPastActivity = isExpired ?? false
		}
	}

	// Custom encoder
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
		try container.encodeIfPresent(isExpired, forKey: .isExpired)
		try container.encodeIfPresent(clientTimezone, forKey: .clientTimezone)
		try container.encodeIfPresent(location, forKey: .location)
		try container.encode(creatorUser, forKey: .creatorUser)
		try container.encodeIfPresent(participantUsers, forKey: .participantUsers)
		try container.encodeIfPresent(invitedUsers, forKey: .invitedUsers)
		try container.encodeIfPresent(chatMessageIds, forKey: .chatMessageIds)
		try container.encode(isPastActivity, forKey: .isPastActivity)
	}

	// Convert a FullFeedActivityDTO to a ProfileActivityDTO
	static func from(fullFeedActivityDTO: FullFeedActivityDTO, isPastActivity: Bool) -> ProfileActivityDTO {
		return ProfileActivityDTO(
			id: fullFeedActivityDTO.id,
			title: fullFeedActivityDTO.title,
			startTime: fullFeedActivityDTO.startTime,
			endTime: fullFeedActivityDTO.endTime,
			note: fullFeedActivityDTO.note,
			icon: fullFeedActivityDTO.icon,
			participantLimit: fullFeedActivityDTO.participantLimit,
			createdAt: fullFeedActivityDTO.createdAt,
			isExpired: fullFeedActivityDTO.isExpired,
			clientTimezone: fullFeedActivityDTO.clientTimezone,
			location: fullFeedActivityDTO.location,
			creatorUser: fullFeedActivityDTO.creatorUser,
			participantUsers: fullFeedActivityDTO.participantUsers,
			invitedUsers: fullFeedActivityDTO.invitedUsers,
			chatMessageIds: fullFeedActivityDTO.chatMessages?.map { $0.id },
			isPastActivity: isPastActivity
		)
	}

	/// Convert this ProfileActivityDTO to a FullFeedActivityDTO for view compatibility.
	/// Note: chatMessages will be empty since ProfileActivityDTO only has chatMessageIds.
	func toFullFeedActivityDTO() -> FullFeedActivityDTO {
		return FullFeedActivityDTO(
			id: id,
			title: title,
			startTime: startTime,
			endTime: endTime,
			location: location,
			note: note,
			icon: icon,
			participantLimit: participantLimit,
			creatorUser: creatorUser,
			participantUsers: participantUsers,
			invitedUsers: invitedUsers,
			chatMessages: nil,  // We only have chatMessageIds, not full messages
			participationStatus: nil,
			isSelfOwned: nil,
			createdAt: createdAt,
			isExpired: isExpired,
			clientTimezone: clientTimezone
		)
	}
}
