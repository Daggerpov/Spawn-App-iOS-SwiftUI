//
//  RecentlySpawnedView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//
import SwiftUI

struct RecentlySpawnedView: View {
	@ObservedObject var viewModel: FriendsTabViewModel
	var recentUser: RecentlySpawnedUserDTO
	@State private var isAdded: Bool = false
	@State private var isFadingOut: Bool = false
	@Binding var selectedFriend: FullFriendUserDTO?
	@Binding var showProfileMenu: Bool

	var body: some View {
		HStack {
			if MockAPIService.isMocking {
				if let pfp = recentUser.user.profilePicture {
					NavigationLink(destination: UserProfileView(user: recentUser.user)) {
						Image(pfp)
							.resizable()
							.scaledToFill()
							.frame(width: 50, height: 50)
							.clipShape(Circle())
					}
				}
			} else {
				NavigationLink(destination: UserProfileView(user: recentUser.user)) {
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

			NavigationLink(destination: ProfileView(user: recentUser.user)) {
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
				Button(action: {
					withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
						isAdded = true
					}
					Task {
						await viewModel.addFriend(friendUserId: recentUser.user.id)
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
							viewModel.removeFromRecentlySpawnedWith(userId: recentUser.user.id)
						}
					}
				}) {
					HStack(spacing: 6) {
						if isAdded {
							Image(systemName: "checkmark")
								.font(.system(size: 14, weight: .bold))
								.foregroundColor(.white)
								.transition(.scale.combined(with: .opacity))
						} else {
							Text("Add +")
								.font(.onestMedium(size: 14))
								.transition(.scale.combined(with: .opacity))
						}
					}
					.foregroundColor(isAdded ? .white : .gray)
					.padding(12)
					.background(
						RoundedRectangle(cornerRadius: 8)
							.fill(isAdded ? universalAccentColor : Color.clear)
							.animation(.easeInOut(duration: 0.3), value: isAdded)
					)
					.overlay(
						RoundedRectangle(cornerRadius: 8)
							.stroke(isAdded ? universalAccentColor : .gray, lineWidth: 1)
							.animation(.easeInOut(duration: 0.3), value: isAdded)
					)
					.frame(minHeight: 46, maxHeight: 46)
				}
				.buttonStyle(PlainButtonStyle())
				.disabled(isAdded)
			}
		}
		.opacity(isFadingOut ? 0 : 1)
		.scaleEffect(isFadingOut ? 0.95 : 1.0)
	}
}
