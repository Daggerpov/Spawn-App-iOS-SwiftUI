//
//  FriendRequestView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI

struct FriendRequestView: View {
	@ObservedObject var viewModel: FriendRequestViewModel

	let user: User
	let closeCallback: () -> ()?  // this is a function passed in from `FriendsTabView`, as a callback function to close the popup

	init(user: User, friendRequestId: UUID, closeCallback: @escaping () -> Void)
	{
		self.user = user
		self.closeCallback = closeCallback
		self.viewModel = FriendRequestViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService() : APIService(), userId: user.id,
			friendRequestId: friendRequestId)
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .center, spacing: 12) {
					// UI, using `user.` properties like: profile picture, username, and name

					// TODO SHANNON

					Text(user.username)
					Text(FormatterService.shared.formatName(user: user))
					Text(user.bio ?? "")
					friendRequestAcceptButton
					friendRequestDeclineButton
				}
				.padding(32)
				.background(universalBackgroundColor)
				.cornerRadius(universalRectangleCornerRadius)
				.shadow(radius: 10)
				.padding(.horizontal, 20)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
			.scrollDisabled(true)
		}
	}
}

extension FriendRequestView {
	var friendRequestAcceptButton: some View {
		Button(action: {
			Task {
				await viewModel.acceptFriendRequest(action: .accept)
			}
			closeCallback()  // closes the popup
		}) {
			Text("accept")
			// TODO SHANNON
		}
	}
	var friendRequestDeclineButton: some View {
		Button(action: {
			Task {
				await viewModel.acceptFriendRequest(action: .decline)
			}
			closeCallback()  // closes the popup
		}) {
			Text("decline")
			// TODO SHANNON
		}

	}

}
