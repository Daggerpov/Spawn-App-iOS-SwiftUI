//
//  OpenFriendTagButtonType.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

enum OpenFriendTagButtonType {
	case friends, tags
	func getDisplayName() -> String {
		switch self {
		case .friends:
			return "Friends"
		case .tags:
			return "Tags"
		}
	}
}
