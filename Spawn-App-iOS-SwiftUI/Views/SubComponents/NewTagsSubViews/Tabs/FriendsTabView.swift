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

	@State private var showingFriendRequestPopup: Bool = false
	@State private var friendInPopUp: User?
	@State private var friendRequestIdInPopup: UUID?

	// for pop-ups:
	@State private var friendRequestOffset: CGFloat = 1000
	// ------------

	@StateObject var searchViewModel: SearchViewModel = SearchViewModel()

	init(user: User) {
		self.user = user
		self.viewModel = FriendsTabViewModel(
			userId: user.id,
			apiService: MockAPIService.isMocking
				? MockAPIService(userId: user.id) : APIService())
	}

	var body: some View {
		ZStack {
			ScrollView {
				Spacer()
				VStack {
					// add friends buttons

					// accept friend req buttons
					SearchView(
						searchPlaceholderText: "search or add friends",
						viewModel: searchViewModel)
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

			if showingFriendRequestPopup {
				friendRequestPopUpView
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
							Button(action: {
								// this executes like .onTapGesture() in JS
								friendInPopUp = friendRequest.senderUser
								friendRequestIdInPopup = friendRequest.id
								showingFriendRequestPopup = true
							}) {
								// this is the Button's display
								if MockAPIService.isMocking {
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
													universalAccentColor,
													lineWidth: 2)
											)
											.padding(.horizontal, 1)
									}
								} else {
									if let pfpUrl = friendRequest.senderUser
										.profilePicture
									{
										AsyncImage(url: URL(string: pfpUrl)) {
											image in
											image
												.resizable()
												.scaledToFill()
												.frame(width: 50, height: 50)
												.clipShape(Circle())
												.overlay(
													Circle().stroke(
														universalAccentColor,
														lineWidth: 2)
												)
												.padding(.horizontal, 1)
										} placeholder: {
											Circle()
												.fill(Color.gray)
												.frame(width: 50, height: 50)
										}
									} else {
										Circle()
											.fill(.white)
											.frame(width: 50, height: 50)
									}
								}
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

				ScrollView(showsIndicators: false) {
					VStack(spacing: 16) {
						ForEach(viewModel.recommendedFriends) { friend in
							RecommendedFriendView(
								viewModel: viewModel, friend: friend)
						}
					}
				}
			}
		}
		.padding(.horizontal, 16)
	}

	var friendsSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			Spacer()

			if viewModel.friends.count > 0 {
				Text("friends")
					.font(.headline)
					.foregroundColor(universalAccentColor)

				ScrollView(showsIndicators: false) {
					VStack(spacing: 16) {
						ForEach(viewModel.friends) { friend in
							HStack {
								if MockAPIService.isMocking {
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
								} else {
									if let pfpUrl = friend.profilePicture {
										AsyncImage(url: URL(string: pfpUrl)) {
											image in
											image
												.resizable()
												.scaledToFill()
												.frame(width: 60, height: 60)
												.clipShape(Circle())
												.overlay(
													Circle().stroke(
														Color.white,
														lineWidth: 2)
												)
										} placeholder: {
											Circle()
												.fill(Color.gray)
												.frame(width: 60, height: 60)
										}
									} else {
										Circle()
											.fill(.white)
											.frame(width: 60, height: 60)
									}
								}

								VStack(alignment: .leading, spacing: 8) {
									Text(friend.username)
										.font(.system(size: 16, weight: .bold))
										.foregroundColor(
											universalBackgroundColor)

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
				}
			} else {
				Text("Add some friends!")
					.foregroundColor(universalAccentColor)
			}
		}
		.padding(.horizontal, 20)
	}

	func closeFriendPopUp() {
		friendRequestOffset = 1000
		showingFriendRequestPopup = false
	}

	struct RecommendedFriendView: View {
		@ObservedObject var viewModel: FriendsTabViewModel
		var friend: User
		@State private var isAdded: Bool = false

		var body: some View {
			HStack {
				if MockAPIService.isMocking {
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
				} else {
					if let pfpUrl = friend.profilePicture {
						AsyncImage(url: URL(string: pfpUrl)) { image in
							image
								.ProfileImageModifier(
									imageType: .friendsListView)
						} placeholder: {
							Circle()
								.fill(Color.gray)
								.frame(width: 50, height: 50)
						}
					} else {
						Circle()
							.fill(.white)
							.frame(width: 50, height: 50)
					}
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

							Image(
								systemName: isAdded
									? "checkmark" : "person.badge.plus"
							)
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
					GridItem(.flexible(), spacing: 8),
				]

				LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
					ForEach(friend.associatedFriendTagsToOwner ?? []) {
						friendTag in
						if !friendTag.isEveryone {
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
			}

		}
	}

}

extension FriendsTabView {
	var friendRequestPopUpView: some View {
		Group {
			if let unwrappedFriendInPopUp = friendInPopUp,
				let unwrappedFriendRequestIdInPopup = friendRequestIdInPopup
			{  // ensuring it isn't null
				ZStack {
					Color(.black)
						.opacity(0.5)
						.onTapGesture {
							closeFriendPopUp()
						}
						.ignoresSafeArea()

					// call your new view here

					FriendRequestView(
						user: unwrappedFriendInPopUp,
						friendRequestId: unwrappedFriendRequestIdInPopup,
						closeCallback: closeFriendPopUp)
				}
			} else {
				// do nothing; maybe figure something out later
				ZStack {
					Color(.black)
						.opacity(0.5)
						.onTapGesture {
							closeFriendPopUp()
						}
						.ignoresSafeArea()

					// call your new view here

					Text(
						"Sorry, this friend request cannot be viewed at the moment. There is an error."
					)
				}
			}
		}
	}
}
