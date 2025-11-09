//
//  ProfileActivityDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-06-15.
//

import Foundation

class ProfileActivityDTO: FullFeedActivityDTO {
	var isPastActivity: Bool

	// Custom initializer to handle the additional property
	init(
		id: UUID,
		title: String? = nil,
		startTime: Date? = nil,
		endTime: Date? = nil,
		location: LocationDTO? = nil,
		note: String? = nil,
		icon: String? = nil,
		creatorUser: BaseUserDTO,
		participantUsers: [BaseUserDTO]? = nil,
		invitedUsers: [BaseUserDTO]? = nil,
		chatMessages: [FullActivityChatMessageDTO]? = nil,
		participationStatus: ParticipationStatus? = nil,
		isSelfOwned: Bool? = nil,
		isPastActivity: Bool = false,
		createdAt: Date? = nil
	) {
		self.isPastActivity = isPastActivity

		super.init(
			id: id,
			title: title,
			startTime: startTime,
			endTime: endTime,
			location: location,
			note: note,
			icon: icon,
			creatorUser: creatorUser,
			participantUsers: participantUsers,
			invitedUsers: invitedUsers,
			chatMessages: chatMessages,
			participationStatus: participationStatus,
			isSelfOwned: isSelfOwned,
			createdAt: createdAt
		)
	}

	// Required for Codable conformance
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.isPastActivity = try container.decode(Bool.self, forKey: .isPastActivity)
		try super.init(from: decoder)
	}

	// CodingKeys to handle the additional property
	private enum CodingKeys: String, CodingKey {
		case isPastActivity
	}

	// Encoding method to handle the additional property
	override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(isPastActivity, forKey: .isPastActivity)
		try super.encode(to: encoder)
	}

	// Convert a FullFeedActivityDTO to a ProfileActivityDTO
	static func from(fullFeedActivityDTO: FullFeedActivityDTO, isPastActivity: Bool) -> ProfileActivityDTO {
		return ProfileActivityDTO(
			id: fullFeedActivityDTO.id,
			title: fullFeedActivityDTO.title,
			startTime: fullFeedActivityDTO.startTime,
			endTime: fullFeedActivityDTO.endTime,
			location: fullFeedActivityDTO.location,
			note: fullFeedActivityDTO.note,
			icon: fullFeedActivityDTO.icon,
			creatorUser: fullFeedActivityDTO.creatorUser,
			participantUsers: fullFeedActivityDTO.participantUsers,
			invitedUsers: fullFeedActivityDTO.invitedUsers,
			chatMessages: fullFeedActivityDTO.chatMessages,
			participationStatus: fullFeedActivityDTO.participationStatus,
			isSelfOwned: fullFeedActivityDTO.isSelfOwned,
			isPastActivity: isPastActivity,
			createdAt: fullFeedActivityDTO.createdAt
		)
	}
}
