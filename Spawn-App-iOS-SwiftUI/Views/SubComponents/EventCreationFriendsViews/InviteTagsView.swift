//
//  InviteTagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import SwiftUI

struct InviteTagsView: View {
	@ObservedObject var viewModel: TagsViewModel
	@State private var creationStatus: CreationStatus = .notCreating

	init(user: User) {
		self.viewModel = TagsViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService(userId: user.id) : APIService(), user: user)
	}

	var body: some View {
		ScrollView {
			if viewModel.tags.count > 0 {
				VStack(alignment: .leading, spacing: 15) {
					Text("TAGS")
						.font(.headline)
						.foregroundColor(universalAccentColor)
				}
				Spacer()
				Spacer()
				tagsSection
			} else {
				Text("Create some friend tags to invite groups of friends to your events.")
					.foregroundColor(universalAccentColor)
			}
		}
		.onAppear {
			Task {
				await viewModel.fetchTags()
			}
		}
		.padding()
		.background(universalBackgroundColor)
	}
}

extension InviteTagsView {
	var tagsSection: some View {
		Group {
			ScrollView {
				VStack(spacing: 15) {
					ForEach(viewModel.tags) { friendTag in
						InviteTagRow(friendTag: friendTag)
							.background(
								RoundedRectangle(cornerRadius: 12)
									.fill(
										Color(hex: friendTag.colorHexCode)
											.opacity(0.5)
									)
									.cornerRadius(
										universalRectangleCornerRadius
									)
							)
							.environmentObject(viewModel)
					}
				}
			}
		}
	}
}

struct InviteTagRow: View {
	@EnvironmentObject var viewModel: TagsViewModel
	var friendTag: FriendTag

	init(friendTag: FriendTag) {
		self.friendTag = friendTag
	}

	var body: some View {
		VStack {
			HStack {
				HStack {
					Text(friendTag.displayName)
				}
				.foregroundColor(.white)
				.font(.title)
				.fontWeight(.semibold)

				Spacer()
				InviteTagFriendsView(friends: friendTag.friends)
			}
			.padding()
			.background(
				RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
					.fill(Color(hex: friendTag.colorHexCode))
			)
		}

	}
}

extension InviteTagRow {

	var titleView: some View {
		Group {
			Text(friendTag.displayName)
				.underline()
		}
	}
}

struct InviteTagFriendsView: View {
	var friends: [User]?
	var body: some View {
		ForEach(friends ?? []) { friend in
			HStack(spacing: -10) {
				if let profilePictureString = friend.profilePicture {
					Image(profilePictureString)
						.ProfileImageModifier(imageType: .eventParticipants)
				}
			}
		}
	}
}
