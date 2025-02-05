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
			? MockAPIService(userId: user.id) : APIService(), userId: user.id)
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
							.environmentObject(viewModel)
					}
				}
			}
		}
	}
}

struct InviteTagRow: View {
	@EnvironmentObject var viewModel: TagsViewModel
	@EnvironmentObject var eventCreationViewModel: EventCreationViewModel

	var friendTag: FriendTag
	@State private var isClicked: Bool = false

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
		}
		.background(
			ZStack {
				// Fill the RoundedRectangle with color
				RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
					.fill(Color(hex: friendTag.colorHexCode).opacity(0.5))

				// Conditionally apply the stroke
				if isClicked {
					RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
						.stroke(universalAccentColor, lineWidth: 5)
				}
			}
		)
		.onTapGesture {
			isClicked.toggle()
			if isClicked {
				eventCreationViewModel.selectedTags.append(friendTag) // Add to selected tags
			} else {
				eventCreationViewModel.selectedTags.removeAll { $0.id == friendTag.id } // Remove from selected tags, if it's already in
			}
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
