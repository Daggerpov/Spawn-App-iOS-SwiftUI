//
//  FriendRow.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct FriendRow: View {
	@EnvironmentObject var viewModel: TagsViewModel
	var friend: UserDTO
	var friendTag: FriendTag

	var body: some View {
		HStack {
			if let pfpUrl = friend.profilePicture {
				AsyncImage(url: URL(string: pfpUrl)) {
					image in
					image
						.ProfileImageModifier(imageType: .tagFriends)
				} placeholder: {
					Circle()
						.fill(Color.gray)
						.frame(width: 35, height: 35)
				}
			} else {
				Circle()
					.fill(Color.gray)
					.frame(width: 35, height: 35)
			}

			Image(systemName: "star.fill")
				.font(.system(size: 10))
			Text(friend.username)
				.font(.headline)
			Spacer()
			if !friendTag.isEveryone{
				Button(action: {
					Task {
						await viewModel.removeFriendFromFriendTag(
							friendUserId: friend.id, friendTagId: friendTag.id)
					}
				}) {
					Image(systemName: "xmark")
				}
			}
		}
		.foregroundColor(.white)
		.frame(maxWidth: .infinity)
		.padding(.bottom, 10)
		.background(
			VStack(spacing: 0) {
				Spacer()
				Rectangle()
					.frame(height: 1)
					.foregroundColor(.black)
					.opacity(0.3)
			}
		)
	}
}
@available(iOS 17.0, *)
#Preview {
	@Previewable @StateObject var viewModel: TagsViewModel = TagsViewModel(
		apiService: MockAPIService(userId: UUID()),
		userId: UUID()
		)

	FriendRow(friend: UserDTO.danielAgapov, friendTag: FriendTag.close).environmentObject(viewModel)
}
