//
//  FriendContainer.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Jennifer Tjen on 2024-11-26.
//

import SwiftUI

struct FriendContainer: View {
	var friendTag: FullFriendTagDTO
	var addFriendsToTagButtonPressedCallback: ((UUID) -> Void)?

	var body: some View {
		VStack {
            AddFriendsToTagButtonView(
                addFriendsToTagButtonPressedCallback:
                    addFriendsToTagButtonPressedCallback,
				friendTagId: friendTag.id
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

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	FriendContainer(
		friendTag: FullFriendTagDTO.close,
		addFriendsToTagButtonPressedCallback: {_ in }
	).environmentObject(appCache)
}
