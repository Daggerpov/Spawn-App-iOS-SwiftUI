//
//  FriendRequestView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI

struct FriendRequestView: View {
	@ObservedObject var viewModel: FriendRequestViewModel
	@State private var hasClickedAccept = false
	@State private var hasClickedDecline = false
    @ObservedObject var friendsTabViewModel: FriendsTabViewModel

	@Binding var showingChoosingTagView: Bool

	let user: BaseUserDTO
    let mutualFriendCount: Int
	let closeCallback: () -> ()?  // this is a function passed in from `FriendsTabView`, as a callback function to close the popup

	init(
        user: BaseUserDTO, friendRequestId: UUID, mutualFriendCount: Int, closeCallback: @escaping () -> Void,
		showingChoosingTagView: Binding<Bool>,
        friendsTabViewModel: FriendsTabViewModel
	) {
		self.user = user
		self.closeCallback = closeCallback
        self.mutualFriendCount = mutualFriendCount
		self.viewModel = FriendRequestViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService() : APIService(), userId: user.id,
			friendRequestId: friendRequestId)
		self._showingChoosingTagView = showingChoosingTagView
        self.friendsTabViewModel = friendsTabViewModel
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .center, spacing: 12) {
					if MockAPIService.isMocking {
						if let pfp = user.profilePicture {
							Image(pfp)
								.resizable()
								.scaledToFill()
								.frame(width: 150, height: 150)
								.clipShape(Circle())
								.overlay(
									Circle().stroke(
										universalAccentColor, lineWidth: 2)
								)

						}
					} else {
						if let pfpUrl = user.profilePicture {
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

					HStack {
						Image(systemName: "star.fill").font(.title2)
						Text(FormatterService.shared.formatName(user: user))
                            .font(.title2).fontWeight(.bold).foregroundColor(universalAccentColor)
					}
                    
                    Text(user.username).font(.title2).foregroundColor(
                        .black.opacity(0.7))
                    
                    if mutualFriendCount > 0 {
                        Text("\(mutualFriendCount) mutual friend\(mutualFriendCount > 1 ? "s" : "")")
                            .font(.system(size: 18))
                            .foregroundColor(universalAccentColor)
                            .padding(.vertical, 4)
                    }
					friendRequestAcceptButton
					friendRequestDeclineButton
				}
				.padding(32)
				.background(universalBackgroundColor)
				.cornerRadius(universalRectangleCornerRadius)
				.shadow(radius: 10)
				.padding(.horizontal, 20)
                .padding(.vertical, 250)
			}
			.scrollDisabled(true)
		}
	}
}

extension FriendRequestView {

	var friendRequestAcceptButton: some View {
		Button(action: {
			Task {
				await viewModel
					.friendRequestAction(action: FriendRequestAction.accept)
                await friendsTabViewModel.fetchAllData()
			}
			closeCallback()
			showingChoosingTagView = true
			hasClickedAccept.toggle()
		}) {
			Text("Accept")
				.foregroundColor(.white)
				.fontWeight(.bold)
				.padding()
				.frame(maxWidth: .infinity)
				.background(
					RoundedRectangle(cornerRadius: 12)
						.fill(
							hasClickedAccept
								? universalBackgroundColor
								: authPageBackgroundColor

						)
						.cornerRadius(
							universalRectangleCornerRadius
						)
				)
		}
	}
	var friendRequestDeclineButton: some View {
		Button(action: {
			Task {
				await viewModel
					.friendRequestAction(action: FriendRequestAction.decline)
                await friendsTabViewModel.fetchAllData()
			}
			closeCallback()
			hasClickedDecline.toggle()
		}) {
			Text("Decline")
				.fontWeight(.bold)
				.foregroundColor(.black)
				.padding()
				.frame(maxWidth: .infinity)
				.background(
					RoundedRectangle(cornerRadius: 12)
						.fill(
							hasClickedDecline
								? universalBackgroundColor.opacity(0.9)
								: universalBackgroundColor.opacity(0.9)
						)
						.cornerRadius(
							universalRectangleCornerRadius
						)
						.overlay(
							RoundedRectangle(cornerRadius: 12)
								.stroke(
									universalPlaceHolderTextColor, lineWidth: 1)

						)
				)
		}

	}

}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	@Previewable @State var showing: Bool = false
	FriendRequestView(
		user: .danielAgapov,
		friendRequestId: UUID(),
        mutualFriendCount: 2,
		closeCallback: {
		},
		showingChoosingTagView: $showing,
        friendsTabViewModel: FriendsTabViewModel(userId: UUID(), apiService: MockAPIService())).environmentObject(appCache)
}
