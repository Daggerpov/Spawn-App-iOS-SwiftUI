//
//  InviteView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import SwiftUI

struct InviteView: View {
	let user: BaseUserDTO
	@Environment(\.dismiss) private var dismiss
	var activityCreationViewModel = ActivityCreationViewModel.shared
	// CRITICAL FIX: Use optional ViewModels to prevent repeated init() calls
	// when SwiftUI recreates this view struct. Initialize lazily in .task.
	@State private var searchViewModel: SearchViewModel?
	@State private var friendsViewModel: FriendsTabViewModel?
	@State private var isInitialized = false

	init(user: BaseUserDTO) {
		self.user = user
		// CRITICAL: Do NOT initialize ViewModels here.
		// ViewModels are initialized lazily in .task to prevent repeated init() calls.
	}

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				// Header
				Text("Invite friends!")
					.font(.headline)
					.foregroundColor(universalAccentColor)
					.padding(.top, 30)

				// Friends section - only show when initialized
				if isInitialized {
					ScrollView {
						VStack(spacing: 20) {
							// Invited section
							if !activityCreationViewModel.selectedFriends.isEmpty {
								invitedFriendsSection
							}

							// Suggested friends section - now using real friends data
							friendsListSection
						}
						.padding(.horizontal)
					}

					// Search bar at bottom
					VStack {
						// Search bar
						if let searchVM = searchViewModel {
							SearchView(searchPlaceholderText: "Search", viewModel: searchVM)
								.padding(.top)
						}

						// Done button
						Button(action: {
							dismiss()
						}) {
							Text(
								"Done Inviting (\(activityCreationViewModel.selectedFriends.count) friends)"
							)
							.font(.headline)
							.foregroundColor(.white)
							.frame(maxWidth: .infinity)
							.padding()
							.background(universalSecondaryColor)
							.cornerRadius(25)
							.padding(.horizontal)
							.padding(.bottom, 15)
						}
					}
					.background(universalBackgroundColor)
				} else {
					// Minimal loading state
					Spacer()
				}
			}
			.background(universalBackgroundColor)
			.navigationBarBackButtonHidden(true)
			.navigationBarItems(
				leading: Button(action: {
					dismiss()
				}) {
					Image(systemName: "chevron.left")
						.foregroundColor(universalAccentColor)
				}
			)
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

				// Load cached data first for instant display, then fetch fresh data
				friendsVM.loadCachedData()
				await friendsVM.fetchAllData()
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
									AsyncImage(url: url) { image in
										image
											.resizable()
											.scaledToFill()
											.frame(width: 30, height: 30)
											.clipShape(Circle())
									} placeholder: {
										Circle()
											.fill(Color.gray)
											.frame(width: 30, height: 30)
									}
								} else {
									Circle()
										.fill(Color.gray)
										.frame(width: 30, height: 30)
								}

								// Use FormatterService to display name
								if let displayName = friend.name {
									Text(displayName.isEmpty ? (friend.username ?? "User") : displayName)
										.font(.subheadline)
										.foregroundColor(.white)
										.lineLimit(1)
								} else {
									Text(friend.username ?? "User")
										.font(.subheadline)
										.foregroundColor(.white)
										.lineLimit(1)

								}

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
				if let friendsVM = friendsViewModel, let searchVM = searchViewModel {
					if friendsVM.friends.isEmpty {
						Text("You have no friends yet")
							.foregroundColor(.gray)
							.padding(.vertical)
					} else {
						// Use filtered friends directly from the view model
						let filteredFriends =
							searchVM.searchText.isEmpty
							? friendsVM.friends
							: friendsVM.friends.filter { friend in
								let searchText = searchVM.searchText.lowercased()
								return (friend.username ?? "").lowercased().contains(searchText)
									|| (friend.name?.lowercased().contains(searchText) ?? false)
									|| (friend.email?.lowercased().contains(searchText) ?? false)
							}

						if filteredFriends.isEmpty {
							Text("No friends match your search")
								.foregroundColor(.gray)
								.padding(.vertical)
						} else {
							ForEach(filteredFriends) { friend in
								FriendListRow(
									friend: friend,
									isSelected: activityCreationViewModel.selectedFriends
										.contains(friend)
								)
								.onTapGesture {
									toggleFriendSelection(friend)
								}
							}
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

// Friend Row Component - renamed to avoid conflict
struct FriendListRow: View {
	let friend: FullFriendUserDTO
	let isSelected: Bool

	var body: some View {
		HStack {
			if let profilePicUrl = friend.profilePicture,
				let url = URL(string: profilePicUrl)
			{
				AsyncImage(url: url) { image in
					image
						.resizable()
						.scaledToFill()
						.frame(width: 50, height: 50)
						.clipShape(Circle())
				} placeholder: {
					Circle()
						.fill(Color.gray)
						.frame(width: 50, height: 50)
				}
			} else {
				Circle()
					.fill(Color.gray)
					.frame(width: 50, height: 50)
			}

			VStack(alignment: .leading) {
				// Use FormatterService to format the name
				let fullName = FormatterService.shared.formatName(user: friend)
				Text(fullName == "No Name" ? (friend.username ?? "User") : fullName)
					.font(.headline)
					.foregroundColor(universalAccentColor)

				Text("@\(friend.username ?? "username")")
					.font(.subheadline)
					.foregroundColor(.gray)
			}

			Spacer()

			Image(
				systemName: isSelected ? "checkmark.circle.fill" : "plus.circle"
			)
			.resizable()
			.frame(width: 30, height: 30)
			.foregroundColor(isSelected ? .green : universalSecondaryColor)
		}
		.padding(.horizontal)
		.padding(.vertical, 5)
		.background(isSelected ? Color.gray.opacity(0.1) : Color.clear)
		.cornerRadius(10)
	}
}

// Add this explicit cast extension to help with type compatibility
extension FullFriendUserDTO {
	// This allows FullFriendUserDTO to be used where BaseUserDTO is expected
	var asBaseUser: BaseUserDTO {
		return BaseUserDTO(
			id: self.id,
			username: self.username,
			profilePicture: self.profilePicture,
			name: self.name,
			bio: self.bio,
			email: self.email
		)
	}
}

@available(iOS 17.0, *)
#Preview {
	InviteView(user: .danielAgapov).environmentObject(AppCache.shared)
}
