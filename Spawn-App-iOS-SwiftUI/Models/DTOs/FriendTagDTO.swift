//
//  FriendTagDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-03-01.
//

import Foundation

struct FriendTagDTO: Identifiable, Codable, Hashable {
	static func == (lhs: FriendTagDTO, rhs: FriendTagDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var displayName: String
	var ownerUserId: UUID
	var colorHexCode: String
	var friendUserIds: [UUID]?
	var isEveryone: Bool

	init(
		id: UUID, displayName: String, ownerUserId: UUID, colorHexCode: String,
		friendUserIds: [UUID]? = nil, isEveryone: Bool = false
	) {
		self.id = id
		self.displayName = displayName
		self.ownerUserId = ownerUserId
		self.colorHexCode = colorHexCode
		self.friendUserIds = friendUserIds
		self.isEveryone = isEveryone
	}
}

extension FriendTagDTO {
	static let everyone: FriendTagDTO = FriendTagDTO(
		id: UUID(),
		displayName: "Everyone",
		ownerUserId: UUID(),
		colorHexCode: universalSecondaryColorHexCode,
		friendUserIds: [UUID(), UUID()],
		isEveryone: true
	)
	static let close = FriendTagDTO(
		id: UUID(), displayName: "Close Friends", ownerUserId: UUID(),
		colorHexCode: eventColorHexCodes[1], friendUserIds: [UUID(), UUID()], isEveryone: false)
	static let sports = FriendTagDTO(
		id: UUID(), displayName: "Sports", ownerUserId: UUID(), colorHexCode: eventColorHexCodes[2],
		friendUserIds: [UUID(), UUID()], isEveryone: false)
	static let hobbies = FriendTagDTO(
		id: UUID(), displayName: "Hobbies", ownerUserId: UUID(), colorHexCode: eventColorHexCodes[3],
		friendUserIds: [UUID(), UUID()], isEveryone: false)
	static let mockTags = [everyone, close, sports, hobbies]
}
