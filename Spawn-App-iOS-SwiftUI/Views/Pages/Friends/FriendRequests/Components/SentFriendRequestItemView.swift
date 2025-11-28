//
//  SentFriendRequestItemView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-17.
//
import SwiftUI

struct SentFriendRequestItemView: View {
	let friendRequest: FetchSentFriendRequestDTO
	let onRemove: () -> Void
	@State private var hasRemoved = false

	var body: some View {
		HStack(spacing: 12) {
			// Clickable profile section
			NavigationLink(destination: UserProfileView(user: friendRequest.receiverUser)) {
				HStack(spacing: 12) {
					// Profile picture
					Group {
						if MockAPIService.isMocking {
							if let pfp = friendRequest.receiverUser.profilePicture {
								Image(pfp)
									.ProfileImageModifier(imageType: .friendsListView)
							}
						} else {
							if let pfpUrl = friendRequest.receiverUser.profilePicture {
								CachedProfileImage(
									userId: friendRequest.receiverUser.id,
									url: URL(string: pfpUrl),
									imageType: .friendsListView
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
						Text(FormatterService.shared.formatName(user: friendRequest.receiverUser))
							.font(.onestSemiBold(size: 14))
							.foregroundColor(universalAccentColor)
							.lineLimit(1)

						Text("@\(friendRequest.receiverUser.username ?? "username")")
							.font(.onestRegular(size: 12))
							.foregroundColor(Color.gray)
							.lineLimit(1)
					}
				}
			}
			.buttonStyle(PlainButtonStyle())

			Spacer()

			// Cancel button
			Button(action: {
				hasRemoved = true
				onRemove()
			}) {
				Text("Cancel")
					.font(.onestMedium(size: 14))
					.foregroundColor(figmaGray700)
					.frame(width: 85, height: 34)
					.background(
						RoundedRectangle(cornerRadius: 8)
							.fill(Color.clear)
							.overlay(
								RoundedRectangle(cornerRadius: 8)
									.stroke(figmaGray700, lineWidth: 1)
							)
					)
			}
			.disabled(hasRemoved)
		}
	}
}
