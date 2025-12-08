//
//  InviteFriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import SwiftUI

struct InviteFriendsView: View {
	var activityCreationViewModel: ActivityCreationViewModel =
		ActivityCreationViewModel.shared
	// CRITICAL FIX: Use optional ViewModels to prevent repeated init() calls
	// when SwiftUI recreates this view struct. Initialize lazily in .task.
	@State private var searchViewModel: SearchViewModel?
	@State private var friendsViewModel: FriendsTabViewModel?
	@State private var isInitialized = false

	let user: BaseUserDTO

	init(user: BaseUserDTO) {
		self.user = user
		// CRITICAL: Do NOT initialize ViewModels here.
		// ViewModels are initialized lazily in .task to prevent repeated init() calls.
	}

	var body: some View {
		VStack(spacing: 20) {
			// Header
			Text("Invite friends!")
				.font(.headline)
				.foregroundColor(universalAccentColor)

			// Friends section - only show when initialized
			if isInitialized {
				ScrollView {
					VStack(spacing: 20) {
						// Invited section
						invitedFriendsSection

						// Suggested friends section - now using real friends data
						friendsListSection
					}
					.padding(.horizontal)
				}
			} else {
				// Minimal loading state
				Color.clear
			}
		}
		.task {
			// CRITICAL: Initialize ViewModels lazily to prevent repeated init() calls
			if searchViewModel == nil {
				searchViewModel = SearchViewModel()
			}
			if friendsViewModel == nil {
				friendsViewModel = FriendsTabViewModel(userId: user.id)
			}

			guard let friendsVM = friendsViewModel, let searchVM = searchViewModel else { return }
			friendsVM.connectSearchViewModel(searchVM)
			isInitialized = true

			// Check if task was cancelled (user navigated away)
			if Task.isCancelled {
				return
			}

			if AppCache.shared.friends.isEmpty {
				await friendsVM.fetchAllData()

				// Check again after async operation
				if Task.isCancelled {
					return
				}

				// After fetching friends, automatically select them all if not already selected
				await MainActor.run {
					if activityCreationViewModel.selectedFriends.isEmpty {
						activityCreationViewModel.selectedFriends = friendsVM.friends
					}
				}
			} else {
				// Load cached friends data through view model
				friendsVM.loadCachedData()

				// Automatically select all friends if not already selected
				if activityCreationViewModel.selectedFriends.isEmpty {
					activityCreationViewModel.selectedFriends = friendsVM.friends
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
				if let friendsVM = friendsViewModel {
					if friendsVM.friends.isEmpty {
						Text("You have no friends yet")
							.foregroundColor(.gray)
							.padding(.vertical)
					} else {
						ForEach(friendsVM.friends) { friend in
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
				} else {
					Text("Loading...")
						.foregroundColor(.gray)
						.padding(.vertical)
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
	var activityCreationViewModel: ActivityCreationViewModel =
		ActivityCreationViewModel.shared

	var friend: FullFriendUserDTO
	@State private var isSelected: Bool = false

	init(friend: FullFriendUserDTO) {
		self.friend = friend
		// Note: isSelected will be initialized based on the current state in onAppear
		self._isSelected = State(initialValue: false)
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
		.onAppear {
			// Initialize selection state based on current selected friends
			isSelected = activityCreationViewModel.selectedFriends.contains(friend)
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	InviteFriendsView(user: .danielAgapov)
}
