//
//  ExpandedTagView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct ExpandedTagView: View {
	@Binding var currentSelectedColorHexCode: String
	var friendTag: FriendTag
	@Binding var isEditingTag: Bool
	var addFriendToTagButtonPressedCallback: (UUID) -> Void

	var body: some View {
		VStack(spacing: 15) {
			HStack {
				Spacer()
			}
			if isEditingTag{
				ColorOptions(
					currentSelectedColorHexCode: $currentSelectedColorHexCode)
			}
			FriendContainer(
				friendTag: friendTag,
				addFriendsToTagButtonPressedCallback: addFriendToTagButtonPressedCallback
			)
		}
		.padding(.horizontal)
		.padding(.bottom)
	}
}
