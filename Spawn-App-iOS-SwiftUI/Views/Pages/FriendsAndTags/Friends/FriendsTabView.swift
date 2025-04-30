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
				VStack(spacing: 16) {
					// Search bar
					SearchView(
						searchPlaceholderText: "Search for friends",
						viewModel: searchViewModel)
                        .padding(.horizontal, 16)
                    
                    // Friends section
					friendsSection
                    
                    // Recently spawned with section
                    recentlySpawnedWithFriendsSection
				}
                .padding(.top, 16)
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
    
    var showAllButtonView: some View {
        Button(action: {
            // TODO DANIEL: fill this in to actually show all
        }) {
            Text("Show All")
                .font(.onestRegular(size: 14))
                .foregroundColor(universalSecondaryColor)
        }
    }
    
	var recentlySpawnedWithFriendsSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			if viewModel.filteredRecommendedFriends.count > 0 {
                HStack{
                    Text("Recently Spawned With")
                        .font(.onestMedium(size: 16))
                        .foregroundColor(universalAccentColor)
                    Spacer()
                    showAllButtonView
                }

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
			if viewModel.filteredFriends.count > 0 {
                HStack{
                    Text("Your Friends (\(viewModel.filteredFriends.count))")
                        .font(.onestMedium(size: 16))
                        .foregroundColor(universalAccentColor)
                    Spacer()
                    showAllButtonView
                }

				ScrollView(showsIndicators: false) {
					VStack(spacing: 16) {
						ForEach(viewModel.filteredFriends) { friend in
                            // Updated Friend Card
                            VStack {
                                HStack {
                                    // Profile picture
                                    if MockAPIService.isMocking {
                                        if let pfp = friend.profilePicture {
                                            Image(pfp)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                        }
                                    } else {
                                        if let pfpUrl = friend.profilePicture {
                                            AsyncImage(url: URL(string: pfpUrl)) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(Circle())
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
                                            .font(.onestBold(size: 16))
                                            .foregroundColor(.white)
                                            
                                        // Display full name
                                        Text(FormatterService.shared.formatName(user: friend))
                                            .font(.onestRegular(size: 14))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    .padding(.leading, 8)

                                    Spacer()
                                    
                                    // More options button
                                    Button(action: {
                                        // Handle more options
                                    }) {
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(.white)
                                            .padding(8)
                                    }
                                }
                                
                                // Friend tags section
                                FriendTagsForFriendView(friend: friend)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(Color.black)
                            .cornerRadius(20)
						}
					}
				}
			} else if viewModel.isSearching && viewModel.filteredFriends.isEmpty {
                Text("No friends found matching your search")
                    .font(.onestRegular(size: 14))
                    .foregroundColor(universalAccentColor)
            } else if viewModel.friends.isEmpty {
				Text("Add some friends!")
                    .font(.onestRegular(size: 14))
					.foregroundColor(universalAccentColor)
			}
		}
		.padding(.horizontal, 16)
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
                    .font(.onestRegular(size: 14))
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
                    .font(.onestRegular(size: 14))
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
                }
            } else {
                if let pfpUrl = friend.profilePicture {
                    AsyncImage(url: URL(string: pfpUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
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
                    .font(.onestBold(size: 16))
                    .foregroundColor(.white)

                // User full name
                Text(FormatterService.shared.formatName(user: friend))
                    .font(.onestRegular(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.leading, 8)

            Spacer()

            Button(action: {
                isAdded = true
                Task {
                    await viewModel.addFriend(friendUserId: friend.id)
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)

                    Text("Add +")
                        .font(.onestMedium(size: 14))
                        .foregroundColor(Color.black)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.black)
        .cornerRadius(16)
    }
}

// Move FriendTagsForFriendView out of FriendsTabView
struct FriendTagsForFriendView: View {
    var friend: FullFriendUserDTO
    var body: some View {
        HStack(spacing: 8) {
            ForEach(friend.associatedFriendTagsToOwner?.prefix(3) ?? []) { friendTag in
                if !friendTag.isEveryone {
                    Text(friendTag.displayName)
                        .font(.onestMedium(size: 12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: friendTag.colorHexCode))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .lineLimit(1)
                }
            }
        }
        .padding(.top, 8)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	FriendsTabView(user: .danielAgapov).environmentObject(appCache)
}
