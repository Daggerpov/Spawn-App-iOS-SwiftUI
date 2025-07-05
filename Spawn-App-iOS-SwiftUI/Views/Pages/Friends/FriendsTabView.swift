//
//  FriendsTabView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct FriendsTabView: View {
	@StateObject private var viewModel: FriendsTabViewModel
	@StateObject var userAuth = UserAuthViewModel.shared
	let user: BaseUserDTO

	@State private var showingFriendRequestPopup: Bool = false
	@State private var friendInPopUp: BaseUserDTO?
	@State private var friendRequestIdInPopup: UUID?
	@State private var mutualFriendCountInPopup: Int?

	// for pop-ups:
	@State private var friendRequestOffset: CGFloat = 1000
	// ------------

	@StateObject private var searchViewModel = SearchViewModel()

	// Profile menu state variables
	@State private var showProfileMenu: Bool = false
	@State private var showRemoveFriendConfirmation: Bool = false
	@State private var showReportDialog: Bool = false
	@State private var showBlockDialog: Bool = false
	@State private var showAddToActivityType: Bool = false
	@State private var selectedFriend: FullFriendUserDTO?
	@State private var blockReason: String = ""

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
			.sheet(isPresented: $showProfileMenu) {
				if let selectedFriend = selectedFriend {
					ProfileMenuView(
						user: selectedFriend,
						showRemoveFriendConfirmation: $showRemoveFriendConfirmation,
						showReportDialog: $showReportDialog,
						showBlockDialog: $showBlockDialog,
						showAddToActivityType: $showAddToActivityType,
						isFriend: true,
						copyProfileURL: { copyProfileURL(for: selectedFriend) },
						shareProfile: { shareProfile(for: selectedFriend) }
					)
					.background(universalBackgroundColor)
					.presentationDetents([.height(364)])
				}
			}
			.alert("Remove Friend", isPresented: $showRemoveFriendConfirmation) {
				Button("Cancel", role: .cancel) {}
				Button("Remove", role: .destructive) {
					if let friendToRemove = selectedFriend {
						Task {
							await viewModel.removeFriend(friendUserId: friendToRemove.id)
						}
					}
				}
			} message: {
				Text("Are you sure you want to remove this friend?")
			}
					.sheet(isPresented: $showReportDialog) {
			ReportUserDrawer(
				user: selectedFriend ?? BaseUserDTO.danielAgapov,
				onReport: { reportType, description in
					// Handle report user action
					// TODO: Implement report functionality
				}
			)
			.presentationDetents([.medium, .large])
			.presentationDragIndicator(.visible)
		}
			.alert("Block User", isPresented: $showBlockDialog) {
				TextField("Reason for blocking", text: $blockReason)
				Button("Cancel", role: .cancel) {
					blockReason = ""
				}
				Button("Block", role: .destructive) {
					if let friendToBlock = selectedFriend,
					   let currentUserId = UserAuthViewModel.shared.spawnUser?.id,
					   !blockReason.isEmpty {
						Task {
							await blockUser(blockerId: currentUserId, blockedId: friendToBlock.id, reason: blockReason)
							blockReason = ""
						}
					}
				}
			} message: {
				Text("Blocking this user will remove them from your friends list and they won't be able to see your profile or activities.")
			}
			.background(
				NavigationLink(
					destination: selectedFriend != nil ? AddToActivityTypeView(user: selectedFriend!) : nil,
					isActive: $showAddToActivityType
				) {
					EmptyView()
				}
				.hidden()
			)
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
    
    var showAllRecommendedButton: some View {
        NavigationLink(destination: FriendSearchView(userId: user.id, displayMode: .recommendedFriends)) {
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
                    showAllRecommendedButton
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
                                                CachedProfileImageFlexible(
                                                    userId: friend.id,
                                                    url: URL(string: pfpUrl),
                                                    width: 50,
                                                    height: 50
                                                )
                                                .transition(.opacity.animation(.easeInOut))
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
                                            Text("@\(friend.username)")
                                                .font(.onestRegular(size: 12))
                                                .foregroundColor(Color.gray)
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        selectedFriend = friend
                                        showProfileMenu = true
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

	// Helper methods for profile actions
	private func copyProfileURL(for user: Nameable) {
		let profileURL = "https://spawn.com/profile/\(user.username)"
		UIPasteboard.general.string = profileURL
		
		// Show a brief toast or notification that the URL was copied
		// You might want to add a toast notification here
	}
	
	private func shareProfile(for user: Nameable) {
		let profileURL = "https://spawn.com/profile/\(user.username)"
		let activityViewController = UIActivityViewController(
			activityItems: [profileURL],
			applicationActivities: nil
		)
		
		// Present the share sheet
		if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
		   let window = windowScene.windows.first {
			window.rootViewController?.present(activityViewController, animated: true, completion: nil)
		}
	}
	
	// Block user functionality
	private func blockUser(blockerId: UUID, blockedId: UUID, reason: String) async {
		do {
			let reportingService = UserReportingService()
			try await reportingService.blockUser(
				blockerId: blockerId,
				blockedId: blockedId,
				reason: reason
			)
			
			// Refresh friends cache to remove the blocked user from friends list
			await AppCache.shared.refreshFriends()
			
		} catch {
			print("Failed to block user: \(error.localizedDescription)")
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
                        CachedProfileImageFlexible(
                            userId: friend.id,
                            url: URL(string: pfpUrl),
                            width: 50,
                            height: 50
                        )
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
                    Text("@\(friend.username)")
                        .font(.onestRegular(size: 12))
                        .foregroundColor(Color.gray)
                    // Show mutual friends count if available
                    if let mutualCount = friend.mutualFriendCount, mutualCount > 0 {
                        Text("\(mutualCount) mutual friend\(mutualCount == 1 ? "" : "s")")
                            .font(.onestRegular(size: 12))
                            .foregroundColor(Color.gray)
                    }
                }
                .padding(.leading, 8)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isAdded = true
                }
                Task {
                    await viewModel.addFriend(friendUserId: friend.id)
                    // Add delay before removing the item
                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                    await viewModel.removeFromRecommended(friendId: friend.id)
                }
            }) {
                HStack(spacing: 6) {
                    if isAdded {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("Add +")
                            .font(.onestMedium(size: 14))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .foregroundColor(isAdded ? .white : .gray)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isAdded ? universalAccentColor : Color.clear)
                        .animation(.easeInOut(duration: 0.3), value: isAdded)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isAdded ? universalAccentColor : .gray, lineWidth: 1)
                        .animation(.easeInOut(duration: 0.3), value: isAdded)
                )
                .frame(minHeight: 46, maxHeight: 46)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isAdded)
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
                        CachedProfileImageFlexible(
                            userId: recentUser.user.id,
                            url: URL(string: pfpUrl),
                            width: 50,
                            height: 50
                        )
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
                    Text("@\(recentUser.user.username)")
                        .font(.onestRegular(size: 12))
                        .foregroundColor(Color.gray)
                }
                .padding(.leading, 8)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isAdded = true
                }
                Task {
                    await viewModel.addFriend(friendUserId: recentUser.user.id)
                    // Add delay before removing the item
                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                    await viewModel.removeFromRecentlySpawnedWith(userId: recentUser.user.id)
                }
            }) {
                HStack(spacing: 6) {
                    if isAdded {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("Add +")
                            .font(.onestMedium(size: 14))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .foregroundColor(isAdded ? .white : .gray)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isAdded ? universalAccentColor : Color.clear)
                        .animation(.easeInOut(duration: 0.3), value: isAdded)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isAdded ? universalAccentColor : .gray, lineWidth: 1)
                        .animation(.easeInOut(duration: 0.3), value: isAdded)
                )
                .frame(minHeight: 46, maxHeight: 46)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isAdded)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
	FriendsTabView(user: .danielAgapov)
}
