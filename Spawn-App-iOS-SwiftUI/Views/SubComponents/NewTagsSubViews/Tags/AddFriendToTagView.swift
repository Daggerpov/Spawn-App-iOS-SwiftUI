//
//  AddFriendToTagView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-06.
//

import SwiftUI

struct AddFriendToTagView: View {
	@ObservedObject var viewModel: AddFriendToTagViewModel
	var userId: UUID
	var friendTagId: UUID

	@StateObject var searchViewModel: SearchViewModel = SearchViewModel()
	var closeCallback: (() -> Void)?

	init(userId: UUID, friendTagId: UUID, closeCallback: @escaping () -> Void) {
		self.userId = userId
		self.friendTagId = friendTagId
		self.closeCallback = closeCallback
		self.viewModel = AddFriendToTagViewModel(
			userId: userId,
			apiService: MockAPIService.isMocking
				? MockAPIService(userId: userId) : APIService())
	}
	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 20) {
				SearchView(
					searchPlaceholderText: "search or add friends",
					viewModel: searchViewModel)
				Group {
					if viewModel.friends.count > 0 {
						ScrollView {
							ForEach(viewModel.friends) { friend in
								FriendRowForAddingFriendsToTag(
									friend: friend, viewModel: viewModel
								)
								.padding(.horizontal)
							}
						}
					} else {
						Text(
							"You've added all your friends to this tag! It's time to add some more friends!"
						)
						.foregroundColor(universalAccentColor)
					}
					doneButtonView
				}
			}
			.frame(
				minHeight: 300,
				idealHeight: 340,
				maxHeight: 380
			)
			.padding(20)
			.background(universalBackgroundColor)
			.cornerRadius(universalRectangleCornerRadius)
		}
		.scrollDisabled(true)  // to get fitting from `ScrollView`, without the actual scrolling
		.onAppear {
			Task {
				await viewModel.fetchFriendsToAddToTag(friendTagId: friendTagId)
			}
		}
	}
}

struct FriendRowForAddingFriendsToTag: View {
	var friend: User
	@State private var isClicked: Bool = false
	@ObservedObject var viewModel: AddFriendToTagViewModel

	init(friend: User, viewModel: AddFriendToTagViewModel) {
		self.friend = friend
		self.viewModel = viewModel
	}

	var body: some View {
		Button(action: {
			// TODO: add to selected friends
			isClicked.toggle()
			viewModel.toggleFriendSelection(friend)
		}) {
			HStack {
				if let pfpUrl = friend.profilePicture {
					AsyncImage(url: URL(string: pfpUrl)) {
						image in
						image
							.ProfileImageModifier(imageType: .tagFriends)
					} placeholder: {
						Circle()
							.fill(Color.gray)
							.frame(width: 35, height: 35)
					}
				} else {
					Circle()
						.fill(Color.gray)
						.frame(width: 35, height: 35)
				}

				Image(systemName: "star.fill")
					.font(.system(size: 10))
				Text(FormatterService.shared.formatName(user: friend))
					.font(.headline)
				Spacer()
			}
			.foregroundColor(isClicked ? .white : universalAccentColor)
			.frame(maxWidth: .infinity)
			.padding(6)
			.background(
				RoundedRectangle(cornerRadius: 12)
					.fill(
						isClicked
							? universalAccentColor
							: universalBackgroundColor
								.opacity(0.5)
					)
					.cornerRadius(
						universalRectangleCornerRadius
					)
			)
		}
	}
}

extension AddFriendToTagView {
	var doneButtonView: some View {
		Button(action: {
			Task {
				await viewModel.addSelectedFriendsToTag(
					friendTagId: friendTagId)
			}
			closeCallback
		}) {
			HStack {
				Text("done")
					.font(.headline)
			}
			.padding(.vertical)
			.foregroundColor(.white)
			.frame(maxWidth: .infinity)
			.background(
				RoundedRectangle(cornerRadius: 12)
					.fill(universalAccentColor)
					.cornerRadius(
						universalRectangleCornerRadius
					)
			)
		}
	}
}
