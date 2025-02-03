//
//  FriendsTabView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct FriendsTabView: View {
	@ObservedObject var viewModel: FriendsTabViewModel
	let user: User

	init(user: User) {
		self.user = user
		self.viewModel = FriendsTabViewModel(
			userId: user.id,
			apiService: MockAPIService.isMocking
				? MockAPIService(userId: user.id) : APIService())
	}

	var body: some View {
		ScrollView {
			VStack {
				// add friends buttons

				// accept friend req buttons
				SearchView(searchPlaceholderText: "search or add friends")
			}
			requestsSection
			recommendedFriendsSection
			friendsSection
		}
		.onAppear {
			Task {
				await viewModel.fetchAllData()
			}
		}
	}

	var requestsSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			if viewModel.incomingFriendRequests.count > 0 {
				Text("requests")
					.font(.headline)
					.foregroundColor(universalAccentColor)
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: 12) {
						ForEach(viewModel.incomingFriendRequests) {
							friendRequest in
							if let senderPfp = friendRequest.senderUser
								.profilePicture
							{
								Image(senderPfp)
									.resizable()
									.scaledToFill()
									.frame(width: 50, height: 50)
									.clipShape(Circle())
									.overlay(
										Circle().stroke(
											universalAccentColor, lineWidth: 2)
									)
									.padding(.horizontal, 1)
							}
						}
					}
					.padding(.vertical, 2)  // Adjust padding for alignment
				}
			}
		}
		.padding(.horizontal, 16)
	}

	//TODO: refine this scetion to only show the greenbackground as the figma design
	var recommendedFriendsSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			if viewModel.recommendedFriends.count > 0 {
				Text("recommended friends")
					.font(.headline)
					.foregroundColor(universalAccentColor)

				VStack(spacing: 16) {
					ForEach(viewModel.recommendedFriends) { friend in
						RecommendedFriendView(viewModel: viewModel, friend: friend)
					}
				}
			}
		}
		.padding(.horizontal, 16)
	}

	var friendsSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			if viewModel.friends.count > 0 {
				Text("friends")
					.font(.headline)
					.foregroundColor(universalAccentColor)

				VStack(spacing: 16) {
					ForEach(viewModel.friends) { friend in
						HStack {
							if let pfp = friend.profilePicture {
								Image(pfp)
									.resizable()
									.scaledToFill()
									.frame(width: 60, height: 60)
									.clipShape(Circle())
									.overlay(
										Circle().stroke(
											Color.white, lineWidth: 2)
									)
							}

							VStack(alignment: .leading, spacing: 8) {
								Text(friend.username)
									.font(.system(size: 16, weight: .bold))
									.foregroundColor(universalBackgroundColor)

								FriendTagsForFriendView(friend: friend)
							}
							.padding(.leading, 8)

							Spacer()
						}
						.padding(.vertical, 16)
						.padding(.horizontal, 20)
						.background(universalAccentColor)
						.cornerRadius(24)
					}
				}
			} else {

			}
		}
		.padding(.horizontal, 20)
	}

	struct RecommendedFriendView: View {
		@ObservedObject var viewModel: FriendsTabViewModel
		var friend: User
		@State private var isAdded: Bool = false

		var body: some View {
			HStack {
				if let pfp = friend.profilePicture {
					Image(pfp)
						.resizable()
						.scaledToFill()
						.frame(width: 50, height: 50)
						.clipShape(Circle())
						.overlay(
							Circle().stroke(
								universalAccentColor, lineWidth: 2)
						)

				}
				VStack(alignment: .leading, spacing: 2) {
					Text(friend.username)
						.font(.system(size: 16, weight: .bold))

					Text(
						FormatterService.shared.formatName(
							user: friend)
					)
					.font(.system(size: 14, weight: .medium))
				}
				.foregroundColor(universalBackgroundColor)
				.padding(.leading, 8)

				Spacer()

				Button(
					action: {
						isAdded = true
						Task {
							await viewModel.addFriend(friendUserId: friend.id)
						}
					}) {
						ZStack {
							Circle()
								.fill(Color.white)
								.frame(width: 50, height: 50)

							Image(systemName: isAdded ? "checkmark" : "person.badge.plus")
								.resizable()
								.scaledToFit()
								.frame(width: 24, height: 24)
								.foregroundColor(
									universalAccentColor)
						}
					}
					.buttonStyle(PlainButtonStyle())
					.shadow(radius: 4)
			}
			.padding(.vertical, 12)
			.padding(.horizontal, 16)
			.background(universalAccentColor)
			.cornerRadius(16)
		}
	}

	struct FriendTagsForFriendView: View {
		var friend: FriendUserDTO
		var body: some View {
			HStack(spacing: 8) {
				// Tags in groups of 2
				let columns = [
					GridItem(.flexible(), spacing: 8),
					GridItem(.flexible(), spacing: 8)
				]

				LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
					ForEach(friend.associatedFriendTagsToOwner ?? []) { friendTag in
						Text(friendTag.displayName)
							.font(.system(size: 10, weight: .medium))
							.padding(.horizontal, 12)
							.padding(.vertical, 6)
							.background(Color(hex: friendTag.colorHexCode))
							.foregroundColor(.white)
							.cornerRadius(12)
							.lineLimit(1) // Ensure text doesn't wrap
							.truncationMode(.tail) // Truncate with "..." if text is too long
					}
				}
			}

		}
	}

}
