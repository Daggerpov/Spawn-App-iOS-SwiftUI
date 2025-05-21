//
//  FriendRow.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct FriendRow: View {
	@EnvironmentObject var viewModel: TagsViewModel
	var friend: BaseUserDTO
	var friendTag: FullFriendTagDTO

	var body: some View {
		HStack {
			if let pfpUrl = friend.profilePicture {
				NavigationLink(destination: ProfileView(user: friend)) {
					AsyncImage(url: URL(string: pfpUrl)) {
						image in
						image
							.ProfileImageModifier(imageType: .tagFriends)
					} placeholder: {
						Circle()
							.fill(Color.gray)
							.frame(width: 35, height: 35)
					}
				}
			} else {
				NavigationLink(destination: ProfileView(user: friend)) {
					Circle()
						.fill(Color.gray)
						.frame(width: 35, height: 35)
				}
			}

			NavigationLink(destination: ProfileView(user: friend)) {
				HStack {
					Image(systemName: "star.fill")
						.font(.system(size: 10))
					Text(friend.username)
						.font(.headline)
				}
				.foregroundColor(.white)
			}
			.buttonStyle(PlainButtonStyle())
			
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
    @Previewable @StateObject var appCache = AppCache.shared
	@Previewable @StateObject var viewModel: TagsViewModel = TagsViewModel(
		apiService: MockAPIService(userId: UUID()),
		userId: UUID()
		)

	FriendRow(friend: .danielAgapov, friendTag: FullFriendTagDTO.close).environmentObject(viewModel).environmentObject(appCache)
}
