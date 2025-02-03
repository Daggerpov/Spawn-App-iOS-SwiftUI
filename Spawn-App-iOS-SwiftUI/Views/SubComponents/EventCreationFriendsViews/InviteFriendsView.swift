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
						IndividualFriendView(friend: friend)
					}
				}
			} else {
				Text("Add some friends to invite them to your events.")
					.font(.subheadline)
					.foregroundColor(universalAccentColor)
			}
		}
		.padding(.horizontal, 20)
	}
}

struct IndividualFriendView: View {
	var friend: FriendUserDTO
	@State private var isSelected: Bool = false

	var body: some View {
		Button(action: {
			if isSelected {
				isSelected = false
			} else {
				isSelected = true
			}
		}) {
			HStack {
				if let pfp = friend.profilePicture {
					Image(pfp)
						.resizable()
						.scaledToFill()
						.frame(width: 60, height: 60)
						.clipShape(Circle())
				}

				VStack(alignment: .leading, spacing: 8) {
					HStack {
						Image(systemName: "star.fill")
							.font(.callout)
						Text(friend.username)
							.font(.system(size: 16, weight: .bold))
					}
					.foregroundColor(isSelected ? .white : universalAccentColor)

					HStack(spacing: 8) {
						ForEach(
							friend.associatedFriendTagsToOwner ?? []
						) { friendTag in
							Text(friendTag.displayName)
								.font(
									.system(size: 10, weight: .medium)
								)
								.padding(.horizontal, 12)
								.padding(.vertical, 6)
								.background(Color(hex: friendTag.colorHexCode))
								.foregroundColor(.white)
								.cornerRadius(12)
						}
					}
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
	InviteFriendsView(user: .danielLee)
}
