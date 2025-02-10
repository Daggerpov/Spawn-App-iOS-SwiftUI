//
//  FriendTagCreationDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-30.
//

import Foundation

struct FriendTagCreationDTO: Identifiable, Codable, Hashable {
	static func == (lhs: FriendTagCreationDTO, rhs: FriendTagCreationDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var displayName: String
	var colorHexCode: String
	var ownerUserId: UUID
	var friendUserIds: [UUID] = []
	var isEveryone: Bool = false

	init(id: UUID, displayName: String, colorHexCode: String, ownerUserId: UUID){
		self.id = id
		self.displayName = displayName
		self.colorHexCode = colorHexCode
		self.ownerUserId = ownerUserId
	}
}
