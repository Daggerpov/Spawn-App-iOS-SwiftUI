//
//  InviteFriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import SwiftUI


struct InviteFriendsView: View {
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
				// TODO: maybe we can implement this later for searching through friends
//				SearchView(searchPlaceholderText: "search or add friends")
			}
			friendsSection
		}
		.onAppear {
			Task {
				await viewModel.fetchAllData()
			}
		}
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
							}

							VStack(alignment: .leading, spacing: 8) {
								Text(friend.username)
									.font(.system(size: 16, weight: .bold))
									.foregroundColor(universalBackgroundColor)

								HStack(spacing: 8) {
									// TODO: replace with real friend tags
									Text("Close Friends")
										.font(
											.system(size: 14, weight: .medium)
										)
										.padding(.horizontal, 12)
										.padding(.vertical, 6)
										.background(Color("TagColorPurple"))
										.foregroundColor(.white)
										.cornerRadius(12)

									Text("Hobbies")
										.font(
											.system(size: 14, weight: .medium)
										)
										.padding(.horizontal, 12)
										.padding(.vertical, 6)
										.background(Color("TagColorGreen"))
										.foregroundColor(.white)
										.cornerRadius(12)
								}
							}
							.padding(.leading, 8)

							Spacer()
						}
						.padding(.vertical, 16)
						.padding(.horizontal, 20)
						.background(universalBackgroundColor)
						.cornerRadius(24)
						.overlay {
							RoundedRectangle(
								cornerRadius: universalRectangleCornerRadius
							)
								.stroke(universalAccentColor, lineWidth: 2)
						}
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

}

@available(iOS 17.0, *)
#Preview
{
	InviteFriendsView(user: .danielLee)
}
