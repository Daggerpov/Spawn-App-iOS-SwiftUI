//
//  InviteFriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import SwiftUI

struct InviteFriendsView: View {
	@ObservedObject var activityCreationViewModel: ActivityCreationViewModel =
		ActivityCreationViewModel.shared
	@StateObject private var searchViewModel = SearchViewModel()

	// Add view models for friends
	@StateObject private var friendsViewModel: FriendsTabViewModel

	let user: BaseUserDTO

	init(user: BaseUserDTO) {
		self.user = user
		// Initialize the view models with _: syntax for StateObject
		self._friendsViewModel = StateObject(
			wrappedValue: FriendsTabViewModel(
				userId: user.id,
				apiService: MockAPIService.isMocking
					? MockAPIService(userId: user.id) : APIService()
			)
		)
	}

	var body: some View {
		VStack(spacing: 20) {
			// Header
			Text("Invite friends!")
				.font(.headline)
				.foregroundColor(universalAccentColor)

			// Friends section
			ScrollView {
				VStack(spacing: 20) {
					// Invited section
					invitedFriendsSection

					// Suggested friends section - now using real friends data
					friendsListSection
				}
				.padding(.horizontal)
			}
		}
		.onAppear {
			friendsViewModel.connectSearchViewModel(searchViewModel)
		}
		.task {
			// Check if task was cancelled (user navigated away)
			if Task.isCancelled {
				return
			}

			if AppCache.shared.friends.isEmpty {
				await friendsViewModel.fetchAllData()

				// Check again after async operation
				if Task.isCancelled {
					return
				}

				// After fetching friends, automatically select them all if not already selected
				await MainActor.run {
					if activityCreationViewModel.selectedFriends.isEmpty {
						activityCreationViewModel.selectedFriends = friendsViewModel.friends
					}
				}
			} else {
				// Load cached friends data through view model
				friendsViewModel.loadCachedData()

				// Automatically select all friends if not already selected
				if activityCreationViewModel.selectedFriends.isEmpty {
					activityCreationViewModel.selectedFriends = friendsViewModel.friends
				}
			}
		}
	}

	// Invited friends section
	var invitedFriendsSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Invited")
				.font(.headline)
				.foregroundColor(universalAccentColor)
				.padding(.leading, 10)

			ScrollView(.horizontal, showsIndicators: false) {
				HStack(spacing: 8) {
					// Create a stable array copy to prevent iteration issues during updates
					let selectedFriendsCopy = activityCreationViewModel.selectedFriends
					ForEach(selectedFriendsCopy) { friend in
						Button(action: {
							// Use the safe removeFriend method instead of direct array manipulation
							activityCreationViewModel.removeFriend(friend)
						}) {
							HStack(spacing: 4) {
								if let profilePicUrl = friend.profilePicture,
									let url = URL(string: profilePicUrl)
								{
									CachedProfileImageFlexible(
										userId: friend.id,
										url: url,
										width: 30,
										height: 30
									)
								} else {
									Circle()
										.fill(Color.gray)
										.frame(width: 30, height: 30)
								}

								Text(friend.name ?? friend.username ?? "User")
									.font(.subheadline)
									.foregroundColor(.white)
									.lineLimit(1)

								Image(systemName: "xmark")
									.font(.caption)
									.foregroundColor(.white)
							}
							.padding(.horizontal, 8)
							.padding(.vertical, 6)
							.background(universalSecondaryColor)
							.clipShape(Capsule())
						}
					}
				}
				.padding(.horizontal, 10)
			}
		}
	}

	// Friends list section with real data and improved search
	var friendsListSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Friends")
				.font(.headline)
				.foregroundColor(universalAccentColor)
				.padding(.leading, 10)

			VStack(spacing: 15) {
				if friendsViewModel.friends.isEmpty {
					Text("You have no friends yet")
						.foregroundColor(.gray)
						.padding(.vertical)
				} else {
					ForEach(friendsViewModel.friends) { friend in
						Button(action: {
							toggleFriendSelection(friend)
						}) {
							FriendListRow(
								friend: friend,
								isSelected: activityCreationViewModel.selectedFriends
									.contains(friend)
							)
						}
						.buttonStyle(PlainButtonStyle())
					}
				}
			}
		}
	}

	private func toggleFriendSelection(_ friend: FullFriendUserDTO) {
		if activityCreationViewModel.selectedFriends.contains(friend) {
			activityCreationViewModel.selectedFriends.removeAll {
				$0.id == friend.id
			}
		} else {
			activityCreationViewModel.selectedFriends.append(friend)
		}
	}
}

struct IndividualFriendView: View {
	@ObservedObject var activityCreationViewModel: ActivityCreationViewModel =
		ActivityCreationViewModel.shared

	var friend: FullFriendUserDTO
	@State private var isSelected: Bool = false

	init(friend: FullFriendUserDTO) {
		self.friend = friend
		if activityCreationViewModel.selectedFriends.contains(friend) {
			self._isSelected = State(initialValue: true)
		} else {
			self._isSelected = State(initialValue: false)
		}
	}

	var body: some View {
		Button(action: {
			isSelected.toggle()
			if isSelected {
				activityCreationViewModel.selectedFriends.append(friend)  // Add to selected friends
			} else {
				activityCreationViewModel.selectedFriends.removeAll {
					$0.id == friend.id
				}  // Remove from selected friends, if it's already in
			}
		}) {
			HStack {
				if let pfpUrl = friend.profilePicture {
					CachedProfileImageFlexible(
						userId: friend.id,
						url: URL(string: pfpUrl),
						width: 60,
						height: 60
					)
				} else {
					Circle()
						.fill(.gray)
						.frame(width: 60, height: 60)
				}

				VStack(alignment: .leading, spacing: 8) {
					HStack {
						Image(systemName: "star.fill")
							.font(.callout)
						Text(friend.username ?? "Username")
							.font(.system(size: 16, weight: .bold))
					}
					.foregroundColor(isSelected ? .white : universalAccentColor)
				}
				.padding(.leading, 8)

				Spacer()
			}
			.padding(.vertical, 16)
			.padding(.horizontal, 20)
			.background(
				isSelected ? universalAccentColor : universalBackgroundColor
			)
			.cornerRadius(24)
			.overlay {
				RoundedRectangle(
					cornerRadius: universalRectangleCornerRadius
				)
				.stroke(universalAccentColor, lineWidth: 2)
			}
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	InviteFriendsView(user: .danielAgapov)
}
