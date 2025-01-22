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
		ScrollView{
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

	//TODO: implement fetchIncomingFriendRequests() from FriendsTabViewModel here to show requests
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
	//TODO: implement fetchRecommendedFriends() from FriendsTabViewModel here to show recommended friends
	var recommendedFriendsSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			if viewModel.recommendedFriends.count > 0 {
				Text("recommended friends")
					.font(.headline)
					.foregroundColor(universalAccentColor)

				VStack(spacing: 16) {
					ForEach(viewModel.recommendedFriends) { friend in
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

							Button(action: {
							}) {
								ZStack {
									Circle()
										.fill(Color.white)
										.frame(width: 50, height: 50)

									Image(systemName: "person.badge.plus")
										.resizable()
										.scaledToFit()
										.frame(width: 24, height: 24)
										.foregroundColor(universalAccentColor)
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
						.background(universalAccentColor)
						.cornerRadius(24)
					}
				}
			} else {

			}
		}
		.padding(.horizontal, 20)
	}

}
