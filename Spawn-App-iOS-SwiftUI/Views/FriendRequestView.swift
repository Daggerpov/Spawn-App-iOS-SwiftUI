//
//  FriendRequestView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI

struct FriendRequestView: View {
	@ObservedObject var viewModel: FriendRequestViewModel
    @State private var isClickedAccept = false
    @State private var isClickedDecline = false

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
                            /*.font(.callout).*/
                        Text(FormatterService.shared.formatName(user: user))
                            .font(.title2).fontWeight(.bold)
                    }
                    Text(user.username).font(.title2).foregroundColor(.black.opacity(0.7))
					friendRequestAcceptButton
					friendRequestDeclineButton
				}
				.padding(32)
				.background(universalBackgroundColor)
				.cornerRadius(universalRectangleCornerRadius)
				.shadow(radius: 10)
				.padding(.horizontal, 20)
                .frame(minHeight: UIScreen.main.bounds.height)
                .frame(maxWidth: .infinity)
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
			}
			closeCallback()  // closes the popup
            isClickedAccept.toggle()
		}) {
            Text("Accept")
                .foregroundColor(.white) // Text color
                .fontWeight(.bold) // Makes text bold
                .padding()
                .frame(maxWidth: .infinity) // Make it stretch if needed
                .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isClickedAccept
                            ? universalBackgroundColor : authPageBackgroundColor

                    )
                    .cornerRadius(
                        universalRectangleCornerRadius
                    )

                // how do we make sure this is responsive LOL
            )

			// TODO SHANNON
		}
	}
	var friendRequestDeclineButton: some View {
//		Button(action: {
//			Task {
//				await viewModel.friendRequestAction(
//					action: FriendRequestAction.decline)
//			}
//			closeCallback()  // closes the popup
//		}) {
//			Text("Decline")
//			// TODO SHANNON
//		}
        
        Button(action: {
            Task {
                await viewModel
                    .friendRequestAction(action: FriendRequestAction.decline)
            }
            closeCallback()  // closes the popup
            isClickedDecline.toggle()
        }) {
            Text("Decline")
                .fontWeight(.bold) // Makes text bold
                .foregroundColor(.black) // Text color
                .padding()
                .frame(maxWidth: .infinity) // Make it stretch if needed
                .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isClickedDecline ?
                        universalBackgroundColor.opacity(0.9)
                        : universalBackgroundColor.opacity(0.9)
                    )
                    .cornerRadius(
                        universalRectangleCornerRadius
                    )
                    .overlay( // ✅ Apply the stroke (outline) here
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(universalPlaceHolderTextColor, lineWidth: 1)

                    )
            )

            // TODO SHANNON
        }

	}

}

@available(iOS 17.0, *)
#Preview {
    FriendRequestView(user: .danielAgapov, friendRequestId: UUID(), closeCallback: {})
    // UUID: UNIQUE UNIVERSAL IDENTIFIER 
}

//.background(
//    RoundedRectangle(cornerRadius: 12)
//        .fill(
//            isClicked
//                ? universalAccentColor
//                : universalBackgroundColor
//                    .opacity(0.5)
//        )
//        .cornerRadius(
//            universalRectangleCornerRadius
//        )
//)
