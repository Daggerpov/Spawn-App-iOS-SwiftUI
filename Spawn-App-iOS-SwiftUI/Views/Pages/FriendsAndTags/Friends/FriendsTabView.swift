//
//  FriendsTabView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct FriendsTabView: View {
	@StateObject private var viewModel: FriendsTabViewModel
	let user: BaseUserDTO
    @EnvironmentObject private var appCache: AppCache

	@State private var showingFriendRequestPopup: Bool = false
	@State var showingChooseTagsPopup: Bool = false
	@State private var friendInPopUp: BaseUserDTO?
	@State private var friendRequestIdInPopup: UUID?
    @State private var mutualFriendCountInPopup: Int?

	// for pop-ups:
	@State private var friendRequestOffset: CGFloat = 1000
	@State private var chooseTagsOffset: CGFloat = 1000
	// ------------

	@StateObject private var searchViewModel = SearchViewModel()

	init(user: BaseUserDTO) {
		self.user = user
		// Initialize the StateObject with proper wrapping to avoid warning
		let vm = FriendsTabViewModel(
			userId: user.id,
			apiService: MockAPIService.isMocking
				? MockAPIService(userId: user.id) : APIService())
		self._viewModel = StateObject(wrappedValue: vm)
	}

	var body: some View {
		ZStack {
			ScrollView {
				Spacer()
				VStack {
					// add friends buttons

					// accept friend req buttons
					SearchView(
						searchPlaceholderText: "Search by name or username",
						viewModel: searchViewModel)
                    Spacer()
                    Spacer()
				}
				requestsSection
				recommendedFriendsSection
				friendsSection
			}
			.onAppear {
				Task {
					await viewModel.fetchAllData()
                    viewModel.connectSearchViewModel(searchViewModel)
				}
			}
            .refreshable {
                // Pull to refresh functionality
                Task {
                    await appCache.refreshFriends()
                    await viewModel.fetchAllData()
                }
            }

			if showingFriendRequestPopup {
				friendRequestPopUpView
			}

			if showingChooseTagsPopup {
				choosingTagViewPopup
			}
		}
	}

	var requestsSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			if viewModel.filteredIncomingFriendRequests.count > 0 {
				Text("Friend Requests")
					.font(.headline)
					.foregroundColor(universalAccentColor)
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: 12) {
						ForEach(viewModel.filteredIncomingFriendRequests) {
							friendRequest in
							Button(action: {
								// this executes like .onTapGesture() in JS
								friendInPopUp = friendRequest.senderUser
								friendRequestIdInPopup = friendRequest.id
                                mutualFriendCountInPopup = friendRequest.mutualFriendCount
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
			if viewModel.filteredRecommendedFriends.count > 0 {
				Text("Recommended Friends")
					.font(.headline)
					.foregroundColor(universalAccentColor)

				ScrollView(showsIndicators: false) {
					VStack(spacing: 16) {
						ForEach(viewModel.filteredRecommendedFriends) { friend in
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

			if viewModel.filteredFriends.count > 0 {
				Text("Friends")
					.font(.headline)
					.foregroundColor(universalAccentColor)

				ScrollView(showsIndicators: false) {
					VStack(spacing: 16) {
						ForEach(viewModel.filteredFriends) { friend in
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
                                        
                                    // Display full name
                                    Text(FormatterService.shared.formatName(user: friend))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(universalBackgroundColor.opacity(0.9))

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
			} else if viewModel.isSearching && viewModel.filteredFriends.isEmpty {
                Text("No friends found matching your search")
                    .foregroundColor(universalAccentColor)
            } else if viewModel.friends.isEmpty {
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

	func closeChoosingTagPopUp() {
		chooseTagsOffset = 1000
		showingChooseTagsPopup = false
		Task {
			await viewModel.fetchAllData()
		}
	}

}

extension FriendsTabView {
	var choosingTagViewPopup: some View {
        Group {
            if let unwrappedFriendInPopUp = friendInPopUp
            {  // ensuring it isn't null
                ZStack {
                    Color(.black)
                        .opacity(0.5)
                        .onTapGesture {
                            closeChoosingTagPopUp()
							closeFriendPopUp()
                        }
                        .ignoresSafeArea(edges: .top)

                    // call your new view here
                    ChoosingTagPopupView(
                        friend: unwrappedFriendInPopUp,
                        userId: user.id,
                        closeCallback: {
                            closeChoosingTagPopUp()
                        }
                    )
                    
                }
            } else {
                // do nothing; maybe figure something out later
                ZStack {
                    Color(.black)
                        .opacity(0.5)
                        .onTapGesture {
                            closeChoosingTagPopUp()
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

	var friendRequestPopUpView: some View {
		Group {
			if let unwrappedFriendInPopUp = friendInPopUp,
				let unwrappedFriendRequestIdInPopup = friendRequestIdInPopup,
                let unwrappedMutualFriendCountInPopup = mutualFriendCountInPopup
			{  // ensuring it isn't null
				ZStack {
					Color(.black)
						.opacity(0.5)
						.onTapGesture {
							closeFriendPopUp()
							closeChoosingTagPopUp()
						}
						.ignoresSafeArea()

					// call your new view here

					FriendRequestView(
						user: unwrappedFriendInPopUp,
						friendRequestId: unwrappedFriendRequestIdInPopup,
                        mutualFriendCount: unwrappedMutualFriendCountInPopup,
						closeCallback: closeFriendPopUp,
						showingChoosingTagView: $showingChooseTagsPopup,
                        friendsTabViewModel: viewModel
					)
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

// Move RecommendedFriendView out of FriendsTabView
struct RecommendedFriendView: View {
    // Use ObservedObject for proper state observation
    @ObservedObject var viewModel: FriendsTabViewModel
    var friend: RecommendedFriendUserDTO
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

                // User full name
                Text(
                    FormatterService.shared.formatName(
                        user: friend)
                )
                .font(.system(size: 14, weight: .medium))
                
                // Add mutual friends count
                if let mutualCount = friend.mutualFriendCount, mutualCount > 0 {
                    Text("\(mutualCount) mutual friend\(mutualCount > 1 ? "s" : "")")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 2)
                }
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

// Move FriendTagsForFriendView out of FriendsTabView
struct FriendTagsForFriendView: View {
    var friend: FullFriendUserDTO
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

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	FriendsTabView(user: .danielAgapov).environmentObject(appCache)
}
