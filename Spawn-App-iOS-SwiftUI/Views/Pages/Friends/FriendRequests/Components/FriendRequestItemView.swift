//
//  FriendRequestItemView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-17.
//
import SwiftUI

struct FriendRequestItemView: View {
	let friendRequest: FetchFriendRequestDTO
	let isIncoming: Bool
	let onAccept: () -> Void
	let onRemove: () -> Void
	@State private var opacity: CGFloat = 1.0

	var body: some View {
		HStack(spacing: 12) {
			// Clickable profile section
			NavigationLink(destination: UserProfileView(user: friendRequest.senderUser)) {
				HStack(spacing: 12) {
					// Profile picture
					Group {
						if MockAPIService.isMocking {
							if let pfp = friendRequest.senderUser.profilePicture {
								Image(pfp)
									.ProfileImageModifier(imageType: .friendsListView)
							}
						} else {
							if let pfpUrl = friendRequest.senderUser.profilePicture {
								CachedProfileImage(
									userId: friendRequest.senderUser.id,
									url: URL(string: pfpUrl),
									imageType: .friendsListView,
								)
							} else {
								Circle()
									.fill(Color.gray)
									.frame(width: 36, height: 36)
							}
						}
					}
					.padding(.leading, 5)
					.padding(.bottom, 4)
					.shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)

					// User info
					VStack(alignment: .leading, spacing: 4) {
						Text(FormatterService.shared.formatName(user: friendRequest.senderUser))
							.font(.onestSemiBold(size: 14))
							.foregroundColor(universalAccentColor)
							.lineLimit(1)

						Text("@\(friendRequest.senderUser.username ?? "username")")
							.font(.onestRegular(size: 12))
							.foregroundColor(Color.gray)
							.lineLimit(1)
					}
				}
			}
			.buttonStyle(PlainButtonStyle())

			Spacer()

			// Action buttons with standardized animation
			HStack(spacing: 8) {
				if isIncoming {
					AnimatedActionButton(
						style: .accept,
						parentOpacity: $opacity,
						onAnimationComplete: onAccept
					)

					AnimatedActionButton(
						style: .remove,
						parentOpacity: $opacity,
						onAnimationComplete: onRemove
					)
				} else {
					AnimatedActionButton(
						style: .cancel,
						parentOpacity: $opacity,
						onAnimationComplete: onRemove
					)
				}
			}
		}
		.opacity(opacity)
	}
}
