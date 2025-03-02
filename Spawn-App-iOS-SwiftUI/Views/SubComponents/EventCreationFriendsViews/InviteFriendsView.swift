//
//  InviteFriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import SwiftUI

struct InviteFriendsView: View {
	@ObservedObject var viewModel: FriendsTabViewModel
	@ObservedObject var eventCreationViewModel: EventCreationViewModel =
		EventCreationViewModel.shared

	let user: UserDTO

	init(user: UserDTO) {
		self.user = user
		self.viewModel = FriendsTabViewModel(
			userId: user.id,
			apiService: MockAPIService.isMocking
				? MockAPIService(userId: user.id) : APIService())
	}

	var body: some View {
		VStack {
			Text("Invite friends:")
				.font(.headline)
				.foregroundColor(universalAccentColor)
			ScrollView {
				//			VStack {
				// TODO: maybe we can implement this later for searching through friends
				//				SearchView(searchPlaceholderText: "search or add friends")
				//			}

				friendsSection
			}
			.onAppear {
				Task {
					await viewModel.fetchAllData()
				}
			}
			Spacer()
		}
		.background(universalBackgroundColor)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	var friendsSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			if viewModel.friends.count > 0 {
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
		.padding()
	}
}

struct IndividualFriendView: View {
	@ObservedObject var eventCreationViewModel: EventCreationViewModel =
		EventCreationViewModel.shared

	var friend: FullFriendUserDTO
	@State private var isSelected: Bool = false

	init(friend: FullFriendUserDTO) {
		self.friend = friend
		if eventCreationViewModel.selectedFriends.contains(friend) {
			self._isSelected = State(initialValue: true)
		} else {
			self._isSelected = State(initialValue: false)
		}
	}

	var body: some View {
		Button(action: {
			isSelected.toggle()
			if isSelected {
				eventCreationViewModel.selectedFriends.append(friend)  // Add to selected friends
			} else {
				eventCreationViewModel.selectedFriends.removeAll {
					$0.id == friend.id
				}  // Remove from selected friends, if it's already in
			}
		}) {
			HStack {
				if let pfpUrl = friend.profilePicture {
					AsyncImage(url: URL(string: pfpUrl)) {
						image in
						image
							.resizable()
							.scaledToFill()
							.frame(width: 60, height: 60)
							.clipShape(Circle())
					} placeholder: {
						Circle()
							.fill(Color.gray)
							.frame(width: 60, height: 60)
					}
				} else {
					Circle()
						.fill(.gray)
						.frame(width: 60, height: 60)
				}

				VStack(alignment: .leading, spacing: 8) {
					HStack {
						Image(systemName: "star.fill")
							.font(.callout)
						Text(friend.username)
							.font(.system(size: 16, weight: .bold))
					}
					.foregroundColor(isSelected ? .white : universalAccentColor)

					// Tags in groups of 2
					let columns = [
						GridItem(.flexible(), spacing: 8),
						GridItem(.flexible(), spacing: 8),
					]

					LazyVGrid(columns: columns, alignment: .leading, spacing: 8)
					{
						ForEach(friend.associatedFriendTagsToOwner ?? []) {
							friendTag in
							Text(friendTag.displayName)
								.font(.system(size: 10, weight: .medium))
								.padding(.horizontal, 12)
								.padding(.vertical, 6)
								.background(Color(hex: friendTag.colorHexCode))
								.foregroundColor(.white)
								.cornerRadius(12)
								.lineLimit(1)  // Ensure text doesn't wrap
								.truncationMode(.tail)  // Truncate with "..." if text is too long
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
	InviteFriendsView(user: .danielAgapov)
}
