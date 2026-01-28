//
//  RecentlySpawnedView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//
import SwiftUI

struct RecentlySpawnedView: View {
	var viewModel: FriendsTabViewModel
	var recentUser: RecentlySpawnedUserDTO
	@State private var opacity: CGFloat = 1.0
	@Binding var selectedFriend: FullFriendUserDTO?
	@Binding var showProfileMenu: Bool

	var body: some View {
		HStack {
			if MockAPIService.isMocking {
				if let pfp = recentUser.user.profilePicture {
					NavigationLink(value: UserProfileNavigationValue(recentUser.user)) {
						Image(pfp)
							.resizable()
							.scaledToFill()
							.frame(width: 50, height: 50)
							.clipShape(Circle())
					}
				}
			} else {
				NavigationLink(value: UserProfileNavigationValue(recentUser.user)) {
					if let pfpUrl = recentUser.user.profilePicture {
						CachedProfileImage(
							userId: recentUser.user.id,
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

			NavigationLink(value: UserProfileNavigationValue(recentUser.user)) {
				VStack(alignment: .leading, spacing: 2) {
					Text(FormatterService.shared.formatName(user: recentUser.user))
						.font(.onestBold(size: 14))
						.foregroundColor(universalAccentColor)
					Text("@\(recentUser.user.username ?? "username")")
						.font(.onestRegular(size: 12))
						.foregroundColor(Color.gray)
				}
				.padding(.leading, 8)
			}
			.buttonStyle(PlainButtonStyle())

			Spacer()

			// Check if user is already a friend
			if viewModel.isFriend(userId: recentUser.user.id) {
				// Show three dots button for existing friends
				Button(action: {
					selectedFriend = FullFriendUserDTO(
						id: recentUser.user.id,
						username: recentUser.user.username,
						profilePicture: recentUser.user.profilePicture,
						name: recentUser.user.name,
						email: recentUser.user.email
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
						await viewModel.addFriend(friendUserId: recentUser.user.id)
					},
					onAnimationComplete: {
						viewModel.removeFromRecentlySpawnedWith(userId: recentUser.user.id)
					}
				)
			}
		}
		.opacity(opacity)
		.scaleEffect(opacity < 1 ? 0.95 : 1.0)
	}
}
