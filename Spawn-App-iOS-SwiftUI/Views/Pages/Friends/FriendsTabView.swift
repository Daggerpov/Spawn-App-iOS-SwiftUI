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

	@State private var showingFriendRequestPopup: Bool = false
	@State private var friendInPopUp: BaseUserDTO?
	@State private var friendRequestIdInPopup: UUID?
	@State private var mutualFriendCountInPopup: Int?

	// for pop-ups:
	@State private var friendRequestOffset: CGFloat = 1000
	// ------------

	@StateObject private var searchViewModel = SearchViewModel()

	init(user: BaseUserDTO) {
		self.user = user
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
					NavigationLink(destination: FriendSearchView(userId: user.id, displayMode: .search)) {
						SearchBarButtonView(
							placeholder: "Search for friends"
						)
						.padding(.horizontal, 16)
					}
                    
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
                    await AppCache.shared.refreshFriends()
                    await viewModel.fetchAllData()
                }
            }
		}
	}
    
    var showAllFriendsButton: some View {
        NavigationLink(destination: FriendSearchView(userId: user.id, displayMode: .allFriends)) {
            Text("Show All")
                .font(.onestRegular(size: 14))
                .foregroundColor(universalSecondaryColor)
        }
    }
    
    var showAllRecentlySpawnedButton: some View {
        NavigationLink(destination: FriendSearchView(userId: user.id, displayMode: .recentlySpawnedWith)) {
            Text("Show All")
                .font(.onestRegular(size: 14))
                .foregroundColor(universalSecondaryColor)
        }
    }
    
	var recentlySpawnedWithFriendsSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			if !viewModel.recentlySpawnedWith.isEmpty {
                HStack{
                    Text("Recently Spawned With")
                        .font(.onestMedium(size: 16))
                        .foregroundColor(universalAccentColor)
                    Spacer()
                    showAllRecentlySpawnedButton
                }

				ScrollView(showsIndicators: false) {
					VStack(spacing: 16) {
						ForEach(viewModel.recentlySpawnedWith, id: \.user.id) { recentUser in
							RecentlySpawnedView(viewModel: viewModel, recentUser: recentUser)
						}
					}
				}
			} else if !viewModel.recommendedFriends.isEmpty {
                // Show "Recommended Friends" when "Recently Spawned With" is empty
                HStack{
                    Text("Recommended Friends")
                        .font(.onestMedium(size: 16))
                        .foregroundColor(universalAccentColor)
                    Spacer()
                }

				ScrollView(showsIndicators: false) {
					VStack(spacing: 16) {
						ForEach(viewModel.recommendedFriends) { friend in
							RecommendedFriendView(viewModel: viewModel, friend: friend)
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
                                            NavigationLink(destination: ProfileView(user: friend)) {
                                                Image(pfp)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(Circle())
                                            }
                                        }
                                    } else {
                                        NavigationLink(destination: ProfileView(user: friend)) {
                                            if let pfpUrl = friend.profilePicture {
                                                AsyncImage(url: URL(string: pfpUrl)) {
                                                    image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 50, height: 50)
                                                        .clipShape(Circle())
                                                        .transition(.opacity.animation(.easeInOut))
                                                } placeholder: {
                                                    ProgressView()
                                                        .frame(width: 50, height: 50)
                                                }
                                            } else {
                                                Image(systemName: "person.circle.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 50, height: 50)
                                                    .foregroundColor(Color.gray.opacity(0.5))
                                            }
                                        }
                                    }
                                    
                                    // Friend info
                                    NavigationLink(destination: ProfileView(user: friend)) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(friend.name ?? friend.username)
                                                .font(.onestMedium(size: 16))
                                                .foregroundColor(universalAccentColor)
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Spacer()
                                    
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
                    NavigationLink(destination: ProfileView(user: friend)) {
                        Image(pfp)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    }
                }
            } else {
                NavigationLink(destination: ProfileView(user: friend)) {
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
            }

            NavigationLink(destination: ProfileView(user: friend)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(FormatterService.shared.formatName(user: friend))
                        .font(.onestBold(size: 14))
                        .foregroundColor(universalAccentColor)
                }
                .padding(.leading, 8)
            }
            .buttonStyle(PlainButtonStyle())

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

// Add RecentlySpawnedView for RecentlySpawnedUserDTO
struct RecentlySpawnedView: View {
    @ObservedObject var viewModel: FriendsTabViewModel
    var recentUser: RecentlySpawnedUserDTO
    @State private var isAdded: Bool = false

    var body: some View {
        HStack {
            if MockAPIService.isMocking {
                if let pfp = recentUser.user.profilePicture {
                    NavigationLink(destination: ProfileView(user: recentUser.user)) {
                        Image(pfp)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    }
                }
            } else {
                NavigationLink(destination: ProfileView(user: recentUser.user)) {
                    if let pfpUrl = recentUser.user.profilePicture {
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
            }

            NavigationLink(destination: ProfileView(user: recentUser.user)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(FormatterService.shared.formatName(user: recentUser.user))
                        .font(.onestBold(size: 14))
                        .foregroundColor(universalAccentColor)
                }
                .padding(.leading, 8)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: {
                isAdded = true
                Task {
                    await viewModel.addFriend(friendUserId: recentUser.user.id)
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
    }
}

@available(iOS 17.0, *)
#Preview {
	FriendsTabView(user: .danielAgapov)
}
