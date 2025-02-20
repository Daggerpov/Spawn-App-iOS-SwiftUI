//
//  FriendContainer.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Jennifer Tjen on 2024-11-26.
//

import SwiftUI

struct FriendContainer: View {
	var friendTag: FriendTag
	@State var creationStatus: CreationStatus = .notCreating
	var addFriendsToTagButtonPressedCallback: ((UUID) -> Void)?

	var body: some View {
		VStack {
			// purely for UI, as logic is handled in `FriendsView`:
			AddTagButtonView(
				creationStatus: $creationStatus,
				addFriendsToTagButtonPressedCallback:
					addFriendsToTagButtonPressedCallback,
				friendTagId: friendTag.id,
				color: .white
			)

			ScrollView {
				if let friends = friendTag.friends, !friends.isEmpty {
					ForEach(friends) { friend in
						FriendRow(friend: friend, friendTag: friendTag)
							.padding(.horizontal)
					}
				} else {
					Text("No friends added yet.")
						.foregroundColor(.black)
						.opacity(0.5)
				}
			}
			.frame(maxHeight: 160)

		}
		.foregroundColor(.white)
		.frame(maxWidth: .infinity)
		.padding(.vertical, 10)
		.background(Color.black.opacity(0.2))
		.cornerRadius(10)
	}
}
