//
//  RecommendedFriendView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//
import SwiftUI

struct RecommendedFriendView: View {
	// Use ObservedObject for proper state observation
	@ObservedObject var viewModel: FriendsTabViewModel
	var friend: RecommendedFriendUserDTO
	@State private var isAdded: Bool = false
	@State private var isFadingOut: Bool = false
	@Binding var selectedFriend: FullFriendUserDTO?
	@Binding var showProfileMenu: Bool

	var body: some View {
		HStack {
			if MockAPIService.isMocking {
				if let pfp = friend.profilePicture {
					NavigationLink(destination: ProfileView(user: friend)) {
						Image(pfp)
							.resizable()
							.scaledToFill()
							.frame(width: 36, height: 36)
							.clipShape(Circle())
					}
				}
			} else {
				NavigationLink(destination: ProfileView(user: friend)) {
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

			NavigationLink(destination: ProfileView(user: friend)) {
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
				Button(action: {
					withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
						isAdded = true
					}
					Task {
						await viewModel.addFriend(friendUserId: friend.id)
						// Add delay before fading out
						try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
						// Fade out animation
						await MainActor.run {
							withAnimation(.easeOut(duration: 0.3)) {
								isFadingOut = true
							}
						}
						// Wait for fade out to complete
						try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds
						// Remove from list
						await MainActor.run {
							viewModel.removeFromRecommended(friendId: friend.id)
						}
					}
				}) {
					HStack {
						if isAdded {
							Image(systemName: "checkmark")
								.font(.system(size: 14, weight: .regular))
								.foregroundColor(Color(hex: colorsGreen700))
								.transition(.scale.combined(with: .opacity))
						} else {
							Text("Add +")
								.font(.onestMedium(size: 14))
								.transition(.scale.combined(with: .opacity))
						}
					}
					.foregroundColor(isAdded ? Color(hex: colorsGreen700) : figmaGray700)
					.frame(width: 71, height: 34)
					.background(
						RoundedRectangle(cornerRadius: 8)
							.fill(Color.clear)
							.animation(.easeInOut(duration: 0.3), value: isAdded)
					)
					.overlay(
						RoundedRectangle(cornerRadius: 8)
							.stroke(isAdded ? Color(hex: colorsGreen700) : figmaGray700, lineWidth: 1)
							.animation(.easeInOut(duration: 0.3), value: isAdded)
					)
				}
				.buttonStyle(PlainButtonStyle())
				.disabled(isAdded)
			}
		}
		.opacity(isFadingOut ? 0 : 1)
		.scaleEffect(isFadingOut ? 0.95 : 1.0)
	}
}
