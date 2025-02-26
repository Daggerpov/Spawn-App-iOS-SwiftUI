//
//  FriendTag.swift
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

struct FriendTag: Identifiable, Codable, Hashable {
	static func == (lhs: FriendTag, rhs: FriendTag) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var displayName: String
	var colorHexCode: String
	var friends: [User]?
	var isEveryone: Bool

	init(
		id: UUID, displayName: String, colorHexCode: String,
		friends: [User]? = nil, isEveryone: Bool = false
	) {
		self.id = id
		self.displayName = displayName
		self.colorHexCode = colorHexCode
		self.friends = friends
		self.isEveryone = isEveryone
	}
}

extension FriendTag {
	static let everyone = FriendTag(
		id: UUID(),
		displayName: "Everyone",
        colorHexCode: universalSecondaryColor,
		friends: [User.haley, User.jennifer, User.shannon, User.michael]
	)
	static let close = FriendTag(
		id: UUID(), displayName: "Close Friends",
		colorHexCode: eventColorHexCodes[1], friends: [User.danielAgapov])
	static let sports = FriendTag(
		id: UUID(), displayName: "Sports", colorHexCode: eventColorHexCodes[2],
		friends: [User.danielLee])
	static let hobbies = FriendTag(
		id: UUID(), displayName: "Hobbies", colorHexCode: eventColorHexCodes[3],
		friends: [User.danielLee])
    static let study = FriendTag(
        id: UUID(), displayName: "Study", colorHexCode: eventColorHexCodes[3],
        friends: [User.danielLee])
	static let mockTags = [everyone, close, sports, hobbies, study]
}
