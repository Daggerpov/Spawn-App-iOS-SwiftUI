//
//  FriendsTabView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct FriendsTabView: View {
	@ObservedObject var viewModel: FriendsTabViewModel
	@ObservedObject var userAuth = UserAuthViewModel.shared
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
	@State private var showReportDialog: Bool = false
	@State private var showBlockDialog: Bool = false
	@State private var showRemoveFriendConfirmation: Bool = false
	@State private var showAddToActivityType: Bool = false
	@State private var selectedFriend: FullFriendUserDTO?
	@State private var blockReason: String = ""
	@State private var navigateToProfile: Bool = false
	
	// Store background refresh task so we can cancel it on disappear
	@State private var backgroundRefreshTask: Task<Void, Never>?

	init(user: BaseUserDTO, viewModel: FriendsTabViewModel? = nil) {
		self.user = user
		
		if let existingViewModel = viewModel {
			self.viewModel = existingViewModel
		} else {
			// Fallback for when no view model is provided (like in previews)
			self.viewModel = FriendsTabViewModel(
				userId: user.id,
				apiService: MockAPIService.isMocking
					? MockAPIService(userId: user.id) : APIService())
		}
	}

	var body: some View {
		ZStack {
			ScrollView {
				VStack(spacing: 24) {
					// Search bar button that navigates to search view
					NavigationLink(destination: FriendSearchView(userId: user.id, displayMode: .search)) {
						SearchBarButtonView(
							placeholder: "Search for friends..."
						)
					}
                    .padding(.horizontal, 25)
                    

                    // Friends section
					friendsSection
                    
                    // Recently spawned with section
                    recentlySpawnedWithFriendsSection
				}
                .padding(.vertical, 20)
                .padding(.bottom, 60) // Add bottom padding to ensure last friend shows fully above nav bar
			}
		.task {
			print("📍 [NAV] FriendsTabView .task started")
			let taskStartTime = Date()
			
			// CRITICAL FIX: Load cached data immediately to unblock UI
			// This prevents the UI from hanging while waiting for API calls
			
			// Load cached data through view model (fast, non-blocking)
			let cacheLoadStart = Date()
			let hasCachedData = await MainActor.run {
				viewModel.loadCachedData()
				viewModel.connectSearchViewModel(searchViewModel)
				// Check if we have any cached data
				return !viewModel.friends.isEmpty || 
					   !viewModel.recommendedFriends.isEmpty ||
					   !viewModel.incomingFriendRequests.isEmpty ||
					   !viewModel.outgoingFriendRequests.isEmpty
			}
			let cacheLoadDuration = Date().timeIntervalSince(cacheLoadStart)
			
			print("📊 [NAV] Cache loaded in \(String(format: "%.3f", cacheLoadDuration))s")
			print("📊 [NAV] Has cached data: \(hasCachedData)")
			
			// Check if task was cancelled
			guard !Task.isCancelled else {
				print("⚠️ [NAV] Task cancelled before determining refresh strategy")
				return
			}
			
			// If cache is empty, block until we have data (critical for UX)
			if !hasCachedData {
				print("🔄 [NAV] No cached friends data - fetching from API on MainActor")
				// Force refresh friend requests first
				await AppCache.shared.forceRefreshAllFriendRequests()
				// Then fetch all data
				await viewModel.fetchAllData()
				let totalDuration = Date().timeIntervalSince(taskStartTime)
				print("⏱️ [NAV] Initial fetch completed in \(String(format: "%.2f", totalDuration))s")
			} else {
				// Cache exists - refresh in background (progressive enhancement)
				print("🔄 [NAV] Starting background refresh for friends data")
				backgroundRefreshTask = Task { @MainActor in
					let refreshStart = Date()
					
					guard !Task.isCancelled else {
						print("⚠️ [NAV] FriendsTabView: Background refresh cancelled before starting")
						return
					}
					
					await AppCache.shared.forceRefreshAllFriendRequests()
					
					guard !Task.isCancelled else {
						print("⚠️ [NAV] FriendsTabView: Background refresh cancelled after requests")
						return
					}
					
					let requestsRefreshDuration = Date().timeIntervalSince(refreshStart)
					print("⏱️ [NAV] Friend requests refresh took \(String(format: "%.2f", requestsRefreshDuration))s")
					
					let fetchStart = Date()
					await viewModel.fetchAllData()
					
					guard !Task.isCancelled else {
						print("⚠️ [NAV] FriendsTabView: Background refresh cancelled after fetchAllData")
						return
					}
					
					let fetchDuration = Date().timeIntervalSince(fetchStart)
					print("⏱️ [NAV] fetchAllData took \(String(format: "%.2f", fetchDuration))s")
					print("✅ [NAV] FriendsTabView: Background refresh completed")
				}
				
				let totalDuration = Date().timeIntervalSince(taskStartTime)
				print("⏱️ [NAV] Total UI update took \(String(format: "%.3f", totalDuration))s")
			}
		}
			.onAppear {
				print("👁️ [NAV] FriendsTabView appeared")
			}
			.onDisappear {
				print("👋 [NAV] FriendsTabView disappearing - cancelling background tasks")
				// Cancel any ongoing background refresh to prevent blocking
				backgroundRefreshTask?.cancel()
				backgroundRefreshTask = nil
				print("👋 [NAV] FriendsTabView disappeared")
			}
            .refreshable {
                // Pull to refresh functionality - user-initiated refresh
                await AppCache.shared.refreshFriends()
                await AppCache.shared.forceRefreshAllFriendRequests()
                await viewModel.fetchAllData()
            }
			.sheet(isPresented: $showProfileMenu) {
				if let selectedFriend = selectedFriend {
					FriendsTabMenuView(
						user: selectedFriend,
						showReportDialog: $showReportDialog,
						showBlockDialog: $showBlockDialog,
						showRemoveFriendConfirmation: $showRemoveFriendConfirmation,
						showAddToActivityType: $showAddToActivityType,
						copyProfileURL: { viewModel.copyProfileURL(for: selectedFriend) },
						shareProfile: { viewModel.shareProfile(for: selectedFriend) },
						navigateToProfile: { navigateToProfile = true }
					)
					.background(universalBackgroundColor)
					.presentationDetents([.height(420)])
				}
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
							await viewModel.blockUser(blockerId: currentUserId, blockedId: friendToBlock.id, reason: blockReason)
							blockReason = ""
						}
					}
				}
			} message: {
				Text("Blocking this user will remove them from your friends list and they won't be able to see your profile or activities.")
			}
			.navigationDestination(isPresented: $navigateToProfile) {
				if let friend = selectedFriend {
					ProfileView(user: friend)
				}
			}
			.alert("Remove Friend", isPresented: $showRemoveFriendConfirmation) {
				Button("Remove", role: .destructive) {
					if let friendToRemove = selectedFriend,
					   let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
						Task {
							await viewModel.removeFriendAndRefresh(currentUserId: currentUserId, friendUserId: friendToRemove.id)
						}
					}
				}
				Button("Cancel", role: .cancel) { }
			} message: {
				Text("Are you sure you want to remove this friend? This action cannot be undone.")
			}
			.sheet(isPresented: $showAddToActivityType) {
				if let friend = selectedFriend {
					AddToActivityTypeView(
						user: friend
					)
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
    
    var showAllRecommendedButton: some View {
        NavigationLink(destination: FriendSearchView(userId: user.id, displayMode: .recommendedFriends)) {
            Text("Show All")
                .font(.onestRegular(size: 14))
                .foregroundColor(universalSecondaryColor)
        }
    }
    
	var recentlySpawnedWithFriendsSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			if !viewModel.recommendedFriends.isEmpty {
                HStack{
                    Text("Recommended Friends")
                        .font(.onestMedium(size: 16))
                        .foregroundColor(universalAccentColor)
                    Spacer()
                    showAllRecommendedButton
                }
                .padding(.leading, 5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(viewModel.recommendedFriends.prefix(3)) { friend in
                            RecommendedFriendView(
                                viewModel: viewModel,
                                friend: friend,
                                selectedFriend: $selectedFriend,
                                showProfileMenu: $showProfileMenu
                            )
                        }
                    }
                    .padding(.trailing, 1)
                }
            }
		}
        .padding(.leading, 20)
        .padding(.trailing, 25)
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
                .padding(.leading, 5)

				ScrollView(showsIndicators: false) {
					VStack(spacing: 12) {
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
                                                    .frame(width: 36, height: 36)
                                                    .clipShape(Circle())
                                            }
                                        }
                                    } else {
                                        NavigationLink(destination: ProfileView(user: friend)) {
                                            if let pfpUrl = friend.profilePicture {
                                                CachedProfileImage(
                                                    userId: friend.id,
                                                    url: URL(string: pfpUrl),
                                                    imageType: .friendsListView
                                                )
                                                .transition(.opacity.animation(.easeInOut))
                                            } else {
                                                Image(systemName: "person.circle.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 36, height: 36)
                                                    .foregroundColor(Color.gray.opacity(0.5))
                                            }
                                        }
                                        .padding(.leading, 5)
                                        .padding(.bottom, 4)
                                        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
                                    }
                                    
                                    // Friend info
                                    NavigationLink(destination: ProfileView(user: friend)) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(friend.name ?? friend.username ?? "User")
                                                .font(.onestSemiBold(size: 14))
                                                .foregroundColor(universalAccentColor)
                                                .lineLimit(1)
                                            Text("@\(friend.username ?? "username")")
                                                .font(.onestRegular(size: 12))
                                                .foregroundColor(Color.gray)
                                                .lineLimit(1)
                                        }
                                        .padding(.leading, 5)
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
                                            .padding(1)
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
        .padding(.leading, 20)
        .padding(.trailing, 25)
	}
}

@available(iOS 17.0, *)
#Preview {
	FriendsTabView(user: .danielAgapov)
}
