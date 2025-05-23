//
//  FullFriendTagDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

// The idea is to have the friends the logged in user has marked
// with a certain tag be contained within that friend tag.

// Tech note: when filtering feed based on friend tags, I can simply check
// the events against the event creator and see whether the event creator is
// one of the `FriendTag`'s `friends`.

import Foundation

/// Like back-end's `FullFriendTagDTO`:
struct FullFriendTagDTO: Identifiable, Codable, Hashable {
	static func == (lhs: FullFriendTagDTO, rhs: FullFriendTagDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var displayName: String
	var colorHexCode: String
	var friends: [BaseUserDTO]?
	var isEveryone: Bool

	init(
		id: UUID, displayName: String, colorHexCode: String,
		friends: [BaseUserDTO]? = nil, isEveryone: Bool = false
	) {
		self.id = id
		self.displayName = displayName
		self.colorHexCode = colorHexCode
		self.friends = friends
		self.isEveryone = isEveryone
	}
}

extension FullFriendTagDTO {
	static let everyone: FullFriendTagDTO = FullFriendTagDTO(
		id: UUID(),
		displayName: "Everyone",
        colorHexCode: universalSecondaryColorHexCode,
		friends: [BaseUserDTO.haley, BaseUserDTO.jennifer, BaseUserDTO.shannon, BaseUserDTO.michael]
	)
	static let close = FullFriendTagDTO(
		id: UUID(), displayName: "Close Friends",
		colorHexCode: eventColorHexCodes[1], friends: [BaseUserDTO.danielAgapov])
	static let sports = FullFriendTagDTO(
		id: UUID(), displayName: "Sports", colorHexCode: eventColorHexCodes[2],
		friends: [BaseUserDTO.danielLee])
	static let hobbies = FullFriendTagDTO(
		id: UUID(), displayName: "Hobbies", colorHexCode: eventColorHexCodes[3],
		friends: [BaseUserDTO.danielLee])
	static let mockTags = [everyone, close, sports, hobbies]
    
    // Empty tag for fallback
    static let empty = FullFriendTagDTO(
        id: UUID(),
        displayName: "Tag Not Found",
        colorHexCode: "#CCCCCC",
        friends: [],
        isEveryone: false
    )
}
