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

	init(user: BaseUserDTO) {
		self.viewModel = TagsViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService(userId: user.id) : APIService(),
			userId: user.id)
	}

	var body: some View {
		VStack {
			Text("Invite friends by tag:")
				.font(.headline)
				.foregroundColor(universalAccentColor)

			ScrollView {
				if viewModel.tags.count > 0 {
					tagsSection
						.padding(.top)
				} else {
					Text(
						"Create some friend tags to invite groups of friends to your events."
					)
					.foregroundColor(universalAccentColor)
				}
			}
			.onAppear {
				Task {
					await viewModel.fetchTags()
				}
			}

			Spacer()
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
							.padding(.top, 6)
							.environmentObject(viewModel)

					}
				}
			}
		}
	}
}

struct InviteTagRow: View {
	@EnvironmentObject var viewModel: TagsViewModel
	@ObservedObject var eventCreationViewModel: EventCreationViewModel =
		EventCreationViewModel.shared

	var friendTag: FullFriendTagDTO
	@State private var isClicked: Bool = false

	init(friendTag: FullFriendTagDTO) {
		self.friendTag = friendTag
		if eventCreationViewModel.selectedTags.contains(friendTag) {
			self._isClicked = State(initialValue: true)
		} else {
			self._isClicked = State(initialValue: false)
		}
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
					RoundedRectangle(
						cornerRadius: universalRectangleCornerRadius
					)
					.stroke(universalAccentColor, lineWidth: 5)
				}
			}
		)
		.padding(.horizontal, 6)
		.onTapGesture {
			isClicked.toggle()
			if isClicked {
				eventCreationViewModel.selectedTags.append(friendTag)  // Add to selected tags
			} else {
				eventCreationViewModel.selectedTags.removeAll {
					$0.id == friendTag.id
				}  // Remove from selected tags, if it's already in
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
	var friends: [BaseUserDTO]?
	var body: some View {
		ForEach(friends ?? []) { friend in
			HStack(spacing: -10) {
				if let pfpUrl = friend.profilePicture {
					AsyncImage(url: URL(string: pfpUrl)) {
						image in
						image
							.ProfileImageModifier(imageType: .eventParticipants)
					} placeholder: {
						Circle()
							.fill(Color.gray)
							.frame(width: 25, height: 25)
					}
				} else {
					Circle()
						.fill(Color.gray)
						.frame(width: 25, height: 25)
				}

			}
		}
	}
}

#Preview {
	InviteTagsView(user: .danielAgapov)
}
