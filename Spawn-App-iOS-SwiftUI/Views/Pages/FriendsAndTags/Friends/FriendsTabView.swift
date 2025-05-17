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
    @State private var showingFriendSearchView = false
    @State private var showingAllFriendsView = false
    @State private var showingRecentlySpawnedWithView = false

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
					// Search bar button that navigates to search view
					SearchBarButtonView(
						placeholder: "Search for friends",
						action: {
							showingFriendSearchView = true
						}
					)
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
            .fullScreenCover(isPresented: $showingFriendSearchView) {
                FriendSearchView(userId: user.id, displayMode: .search)
            }
            .fullScreenCover(isPresented: $showingAllFriendsView) {
                FriendSearchView(userId: user.id, displayMode: .allFriends)
            }
            .fullScreenCover(isPresented: $showingRecentlySpawnedWithView) {
                FriendSearchView(userId: user.id, displayMode: .recentlySpawnedWith)
            }
		}
	}
    
    var showAllFriendsButton: some View {
        Button(action: {
            showingAllFriendsView = true
        }) {
            Text("Show All")
                .font(.onestRegular(size: 14))
                .foregroundColor(universalSecondaryColor)
        }
    }
    
    var showAllRecentlySpawnedButton: some View {
        Button(action: {
            showingRecentlySpawnedWithView = true
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
                    showAllRecentlySpawnedButton
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
                    showAllFriendsButton
                }

				ScrollView(showsIndicators: false) {
					VStack(spacing: 16) {
						ForEach(viewModel.filteredFriends.prefix(5)) { friend in
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
                                        // Display full name
                                        Text(FormatterService.shared.formatName(user: friend))
                                            .font(.onestRegular(size: 14))
                                        Text("@\(friend.username)")
                                            .font(.onestBold(size: 16))
                                    }
                                    .foregroundColor(universalAccentColor)
                                    .padding(.leading, 8)

                                    Spacer()
                                    
                                    // More options button
                                    Button(action: {
                                        // Handle more options
                                    }) {
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(
                                                universalAccentColor
                                            )
                                            .padding(8)
                                    }
                                }
                            }
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
                Text(FormatterService.shared.formatName(user: friend))
                    .font(.onestBold(size: 14))
                Text("@\(friend.username)")
                    .font(.onestRegular(size: 12))
            }
            .padding(.leading, 8)

            Spacer()

            Button(action: {
                isAdded = true
                Task {
                    await viewModel.addFriend(friendUserId: friend.id)
                }
            }) {

                Text("Add +")
                    .font(.onestMedium(size: 14))
                    .padding(12)
                    .background(
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .inset(by: 0.75)
                                    .stroke(.gray)
                            )
                    )
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 12)
        .cornerRadius(16)
        .foregroundColor(universalAccentColor)
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
