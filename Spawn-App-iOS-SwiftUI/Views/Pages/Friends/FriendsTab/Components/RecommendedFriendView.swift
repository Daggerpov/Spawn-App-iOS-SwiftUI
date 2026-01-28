//
//  RecommendedFriendView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//
import SwiftUI

struct RecommendedFriendView: View {
	var viewModel: FriendsTabViewModel
	var friend: RecommendedFriendUserDTO
	@State private var opacity: CGFloat = 1.0
	@Binding var selectedFriend: FullFriendUserDTO?
	@Binding var showProfileMenu: Bool

	var body: some View {
		HStack {
			if MockAPIService.isMocking {
				if let pfp = friend.profilePicture {
					NavigationLink(value: UserProfileNavigationValue(friend)) {
						Image(pfp)
							.resizable()
							.scaledToFill()
							.frame(width: 36, height: 36)
							.clipShape(Circle())
					}
				}
			} else {
				NavigationLink(value: UserProfileNavigationValue(friend)) {
					if let pfpUrl = friend.profilePicture {
						CachedProfileImage(
							userId: friend.id,
							url: URL(string: pfpUrl),
							imageType: .friendsListView
						)
					} else {
						Circle()
							.fill(.white)
							.frame(width: 36, height: 36)
					}
				}
				.padding(.leading, 5)
				.padding(.bottom, 4)
				.shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
			}

			NavigationLink(value: UserProfileNavigationValue(friend)) {
				VStack(alignment: .leading, spacing: 4) {
					Text(FormatterService.shared.formatName(user: friend))
						.font(.onestSemiBold(size: 14))
						.foregroundColor(universalAccentColor)
					Text("@\(friend.username ?? "username")")
						.font(.onestRegular(size: 12))
						.foregroundColor(Color.gray)
				}
				.padding(.leading, 4)
			}
			.buttonStyle(PlainButtonStyle())

			Spacer()

			// Check if user is already a friend
			if viewModel.isFriend(userId: friend.id) {
				// Show three dots button for existing friends
				Button(action: {
					selectedFriend = FullFriendUserDTO(
						id: friend.id,
						username: friend.username,
						profilePicture: friend.profilePicture,
						name: friend.name,
						email: friend.email
					)
					showProfileMenu = true
				}) {
					Image(systemName: "ellipsis")
						.foregroundColor(universalAccentColor)
						.padding(8)
				}
			} else {
				AnimatedActionButton(
					style: .add,
					delayBeforeFadeOut: 1_000_000_000,  // 1 second (matching original behavior)
					parentOpacity: $opacity,
					onImmediateAction: {
						await viewModel.addFriend(friendUserId: friend.id)
					},
					onAnimationComplete: {
						viewModel.removeFromRecommended(friendId: friend.id)
					}
				)
			}
		}
		.opacity(opacity)
		.scaleEffect(opacity < 1 ? 0.95 : 1.0)
	}
}
