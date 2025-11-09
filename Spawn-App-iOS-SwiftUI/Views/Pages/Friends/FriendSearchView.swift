//
//  FriendSearchView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 5/17/25.
//

import Combine
import SwiftUI

// Define the different modes the view can operate in
enum FriendListDisplayMode {
	case search
	case allFriends
	case recentlySpawnedWith
	case recommendedFriends
}

struct FriendSearchView: View {
	@Environment(\.dismiss) private var dismiss
	@StateObject private var searchViewModel = SearchViewModel()
	@StateObject private var viewModel: FriendsTabViewModel

	// Mode determines what content to display
	var displayMode: FriendListDisplayMode

	init(userId: UUID? = nil, displayMode: FriendListDisplayMode = .search) {
		let id =
			userId ?? (UserDefaults.standard.string(forKey: "currentUserId").flatMap { UUID(uuidString: $0) } ?? UUID())
		self._viewModel = StateObject(
			wrappedValue: FriendsTabViewModel(
				userId: id,
				apiService: MockAPIService.isMocking ? MockAPIService(userId: id) : APIService())
		)
		self.displayMode = displayMode
	}

	// Title based on display mode
	private var titleText: String {
		switch displayMode {
		case .search:
			return "Find Friends"
		case .allFriends:
			return "Your Friends"
		case .recentlySpawnedWith:
			return "Recently Spawned With"
		case .recommendedFriends:
			return "Recommended Friends"
		}
	}

	var body: some View {
		VStack(spacing: 0) {
			// Header (simplified to match TagDetailView)
			HStack {
				Button(action: {
					dismiss()
				}) {
					Image(systemName: "chevron.left")
						.font(.title3)
				}

				Spacer()

				Text(titleText)
					.font(.title3)
					.fontWeight(.semibold)

				Spacer()

				// Empty view to balance the back button
				Image(systemName: "chevron.left")
					.font(.title3)
					.foregroundColor(.clear)
			}
			.foregroundColor(universalAccentColor)
			.padding(.vertical, 25)
			.padding(.horizontal, 25)

			// Search bar
			if displayMode == .search || displayMode == .allFriends {
				SearchBarView(
					searchText: $searchViewModel.searchText,
					isSearching: $searchViewModel.isSearching,
					placeholder: "Search for friends",
					autofocus: displayMode == .search
				)
				.padding(.bottom, 8)
				.padding(.horizontal, 25)
			}

			// Content based on display mode
			ScrollView {
				VStack(spacing: 16) {
					switch displayMode {
					case .search:
						if searchViewModel.searchText.isEmpty {
							recentlySpawnedWithView
						} else {
							searchResultsView
						}
					case .allFriends:
						allFriendsView
					case .recentlySpawnedWith:
						recentlySpawnedWithView
					case .recommendedFriends:
						recommendedFriendsView
					}
				}
				.padding(.vertical, 16)
			}
			.navigationBarHidden(true)
			.task {
				// Load appropriate data based on display mode
				switch displayMode {
				case .search:
					await viewModel.fetchRecentlySpawnedWith()
				case .allFriends:
					// Load cached friends data through view model, then fetch if needed
					await MainActor.run {
						viewModel.loadCachedData()
					}
					if viewModel.friends.isEmpty {
						await viewModel.fetchAllData()
					}
				case .recentlySpawnedWith:
					await viewModel.fetchRecentlySpawnedWith()
				case .recommendedFriends:
					// Load cached recommended friends through view model, then fetch if needed
					await MainActor.run {
						viewModel.loadCachedData()
					}
					if viewModel.recommendedFriends.isEmpty {
						await viewModel.fetchRecommendedFriends()
					}
				}

				viewModel.connectSearchViewModel(searchViewModel)
			}
		}
		.background(universalBackgroundColor)
	}

	var searchResultsView: some View {
		VStack(spacing: 12) {
			// Background for loading state
			Color.clear.frame(width: 0, height: 0)
				.background(universalBackgroundColor)
			if viewModel.isLoading {
				ProgressView()
					.padding(.top, 24)
					.background(universalBackgroundColor)
			} else if viewModel.searchResults.isEmpty && searchViewModel.searchText.count > 0 {
				Text("No results found")
					.font(.onestRegular(size: 16))
					.foregroundColor(universalAccentColor)
					.padding(.top, 24)
			} else {
				ForEach(viewModel.searchResults) { user in
					FriendRowView(user: user, viewModel: viewModel)
						.padding(.leading, 20)
						.padding(.trailing, 25)
				}
			}
		}
		.padding(.bottom, viewModel.searchResults.isEmpty ? 0 : 100)
		.background(universalBackgroundColor)
	}

	var allFriendsView: some View {
		VStack(spacing: 12) {
			// Background for loading state
			Color.clear.frame(width: 0, height: 0)
				.background(universalBackgroundColor)
			if viewModel.isLoading {
				ProgressView()
					.padding(.top, 24)
					.background(universalBackgroundColor)
			} else if viewModel.filteredFriends.isEmpty {
				Text("No friends found")
					.font(.onestRegular(size: 16))
					.foregroundColor(universalAccentColor)
					.padding(.top, 24)
			} else {
				ForEach(viewModel.filteredFriends) { friend in
					FriendRowView(friend: friend, viewModel: viewModel, isExistingFriend: true)
						.padding(.leading, 20)
						.padding(.trailing, 25)
				}
			}
		}
		.padding(.bottom, viewModel.filteredFriends.isEmpty ? 0 : 100)
		.background(universalBackgroundColor)
	}

	var recentlySpawnedWithView: some View {
		VStack(alignment: .leading, spacing: 12) {
			// Background for loading state
			Color.clear.frame(width: 0, height: 0)
				.background(universalBackgroundColor)
			if viewModel.isLoading {
				ProgressView()
					.padding(.top, 24)
					.background(universalBackgroundColor)
			} else if viewModel.recentlySpawnedWith.isEmpty {
				Text("No recent spawns found")
					.font(.onestRegular(size: 14))
					.foregroundColor(universalAccentColor)
					.padding(.horizontal, 16)
					.padding(.top, 24)
			} else {
				ForEach(viewModel.recentlySpawnedWith, id: \.user.id) { recentUser in
					FriendRowView(user: recentUser.user, viewModel: viewModel)
						.padding(.leading, 20)
						.padding(.trailing, 25)
				}
			}
		}
		.padding(.bottom, viewModel.recentlySpawnedWith.isEmpty ? 0 : 100)
		.background(universalBackgroundColor)
	}

	var recommendedFriendsView: some View {
		VStack(spacing: 12) {
			// Background for loading state
			Color.clear.frame(width: 0, height: 0)
				.background(universalBackgroundColor)
			if viewModel.isLoading {
				ProgressView()
					.padding(.top, 24)
					.background(universalBackgroundColor)
			} else if viewModel.recommendedFriends.isEmpty {
				Text("No recommended friends found")
					.font(.onestRegular(size: 16))
					.foregroundColor(universalAccentColor)
					.padding(.top, 24)
			} else {
				ForEach(viewModel.recommendedFriends) { recommendedFriend in
					FriendRowView(recommendedFriend: recommendedFriend, viewModel: viewModel)
						.padding(.leading, 20)
						.padding(.trailing, 25)
				}
			}
		}
		.padding(.bottom, viewModel.recommendedFriends.isEmpty ? 0 : 100)
		.background(universalBackgroundColor)
	}
}

// Unified FriendRowView that can work with either BaseUserDTO or FullFriendUserDTO
struct FriendRowView: View {
	var user: Nameable? = nil
	var friend: FullFriendUserDTO? = nil
	var recommendedFriend: RecommendedFriendUserDTO? = nil
	var viewModel: FriendsTabViewModel
	var isExistingFriend: Bool = false
	@State private var isAdded: Bool = false

	// Profile menu state variables
	@State private var showProfileMenu: Bool = false
	@State private var showRemoveFriendConfirmation: Bool = false
	@State private var showReportDialog: Bool = false
	@State private var showBlockDialog: Bool = false
	@State private var showAddToActivityType: Bool = false
	@State private var blockReason: String = ""
	@ObservedObject var userAuth = UserAuthViewModel.shared

	// Computed property for the user object
	private var userForProfile: Nameable {
		return user ?? friend ?? recommendedFriend ?? user!
	}

	var body: some View {
		HStack {
			// Profile picture - works with either user, friend, or recommendedFriend
			let profilePicture = user?.profilePicture ?? friend?.profilePicture ?? recommendedFriend?.profilePicture

			// Create NavigationLink around the profile picture
			NavigationLink(destination: ProfileView(user: userForProfile)) {
				if let pfpUrl = profilePicture {
					if MockAPIService.isMocking {
						Image(pfpUrl)
							.resizable()
							.scaledToFill()
							.frame(width: 36, height: 36)
							.clipShape(Circle())
					} else {
						CachedProfileImage(
							userId: userForProfile.id,
							url: URL(string: pfpUrl),
							imageType: .friendsListView
						)
					}
				} else {
					Circle()
						.fill(.gray)
						.frame(width: 36, height: 36)
				}
			}
			.padding(.leading, 5)
			.padding(.bottom, 4)
			.shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)

			// Navigation link for name and username
			NavigationLink(destination: ProfileView(user: userForProfile)) {
				VStack(alignment: .leading, spacing: 4) {
					// Works with user, friend, or recommendedFriend
					if let user = user {
						Text(FormatterService.shared.formatName(user: user))
							.font(.onestSemiBold(size: 14))
							.foregroundColor(universalAccentColor)
						Text("@\(user.username ?? "username")")
							.font(.onestRegular(size: 12))
							.foregroundColor(Color.gray)
					} else if let friend = friend {
						Text(FormatterService.shared.formatName(user: friend))
							.font(.onestSemiBold(size: 14))
							.foregroundColor(universalAccentColor)
						Text("@\(friend.username ?? "username")")
							.font(.onestRegular(size: 12))
							.foregroundColor(Color.gray)
					} else if let recommendedFriend = recommendedFriend {
						Text(FormatterService.shared.formatName(user: recommendedFriend))
							.font(.onestSemiBold(size: 14))
							.foregroundColor(universalAccentColor)
						Text("@\(recommendedFriend.username ?? "username")")
							.font(.onestRegular(size: 12))
							.foregroundColor(Color.gray)
						// Show mutual friends count if available
						if let mutualCount = recommendedFriend.mutualFriendCount, mutualCount > 0 {
							Text("\(mutualCount) mutual friend\(mutualCount == 1 ? "" : "s")")
								.font(.onestRegular(size: 12))
								.foregroundColor(Color.gray)
						}
					}
				}
				.padding(.leading, 8)
			}
			.buttonStyle(PlainButtonStyle())

			Spacer()

			// Different controls depending on the context
			let targetUserId = friend?.id ?? user?.id ?? recommendedFriend?.id ?? UUID()
			let isFriendStatus = isExistingFriend || viewModel.isFriend(userId: targetUserId)

			if isFriendStatus {
				// Show three dots button for existing friends
				Button(action: {
					showProfileMenu = true
				}) {
					Image(systemName: "ellipsis")
						.foregroundColor(universalAccentColor)
						.padding(8)
				}
			} else if (friend != nil || user != nil || recommendedFriend != nil) && !isAdded {
				// Show add button for non-friends or users
				Button(action: {
					withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
						isAdded = true
					}
					Task {
						await viewModel.addFriend(friendUserId: targetUserId)
						// Add delay before removing the item
						try? await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 seconds
						if friend != nil {
							viewModel.removeFromSearchResults(userId: targetUserId)
						} else if user != nil {
							viewModel.removeFromRecentlySpawnedWith(userId: targetUserId)
						} else if recommendedFriend != nil {
							viewModel.removeFromRecommended(friendId: targetUserId)
						}
					}
				}) {
					HStack {
						if isAdded {
							Image(systemName: "checkmark")
								.font(.system(size: 14, weight: .regular))
								.foregroundColor(Color(hex: colorsGreen700))
								.transition(.scale.combined(with: .opacity))
						} else {
							Text("Add +")
								.font(.onestMedium(size: 14))
								.transition(.scale.combined(with: .opacity))
						}
					}
					.foregroundColor(isAdded ? Color(hex: colorsGreen700) : figmaGray700)
					.frame(width: 71, height: 34)
					.background(
						RoundedRectangle(cornerRadius: 8)
							.fill(Color.clear)
							.animation(.easeInOut(duration: 0.3), value: isAdded)
					)
					.overlay(
						RoundedRectangle(cornerRadius: 8)
							.stroke(isAdded ? Color(hex: colorsGreen700) : figmaGray700, lineWidth: 1)
							.animation(.easeInOut(duration: 0.3), value: isAdded)
					)
				}
				.disabled(isAdded)
			}
		}
		.sheet(isPresented: $showProfileMenu) {
			ProfileMenuView(
				user: userForProfile,
				showRemoveFriendConfirmation: $showRemoveFriendConfirmation,
				showReportDialog: $showReportDialog,
				showBlockDialog: $showBlockDialog,
				showAddToActivityType: $showAddToActivityType,
				isFriend: true,  // Since this is only shown for existing friends
				copyProfileURL: { copyProfileURL(for: userForProfile) },
				shareProfile: { shareProfile(for: userForProfile) }
			)
			.background(universalBackgroundColor)
			.presentationDetents([.height(364)])
		}
		.alert("Remove Friend", isPresented: $showRemoveFriendConfirmation) {
			Button("Cancel", role: .cancel) {}
			Button("Remove", role: .destructive) {
				Task {
					let targetUserId = userForProfile.id
					await viewModel.removeFriend(friendUserId: targetUserId)
				}
			}
		} message: {
			Text("Are you sure you want to remove this friend?")
		}
		.sheet(isPresented: $showReportDialog) {
			ReportUserDrawer(
				user: userForProfile,
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
				if let currentUserId = userAuth.spawnUser?.id,
					!blockReason.isEmpty
				{
					Task {
						await blockUser(blockerId: currentUserId, blockedId: userForProfile.id, reason: blockReason)
						blockReason = ""
					}
				}
			}
		} message: {
			Text(
				"Blocking this user will remove them from your friends list and they won't be able to see your profile or activities."
			)
		}
		.navigationDestination(isPresented: $showAddToActivityType) {
			AddToActivityTypeView(user: userForProfile)
		}
	}

	// Helper methods for profile actions
	private func copyProfileURL(for user: Nameable) {
		ServiceConstants.generateProfileShareCodeURL(for: user.id) { profileURL in
			let url = profileURL ?? ServiceConstants.generateProfileShareURL(for: user.id)

			// Clear the pasteboard first to avoid any contamination
			UIPasteboard.general.items = []

			// Set only the URL string to the pasteboard
			UIPasteboard.general.string = url.absoluteString

			// Show notification toast
			DispatchQueue.main.async {
				InAppNotificationManager.shared.showNotification(
					title: "Link copied to clipboard",
					message: "Profile link has been copied to your clipboard",
					type: .success,
					duration: 5.0
				)
			}
		}
	}

	private func shareProfile(for user: Nameable) {
		ServiceConstants.generateProfileShareCodeURL(for: user.id) { profileURL in
			let url = profileURL ?? ServiceConstants.generateProfileShareURL(for: user.id)
			let shareText =
				"Check out \(FormatterService.shared.formatName(user: user))'s profile on Spawn! \(url.absoluteString)"

			let activityViewController = UIActivityViewController(
				activityItems: [shareText],
				applicationActivities: nil
			)

			// Present the activity view controller
			if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
				let window = windowScene.windows.first
			{

				var topController = window.rootViewController
				while let presentedViewController = topController?.presentedViewController {
					topController = presentedViewController
				}

				if let popover = activityViewController.popoverPresentationController {
					popover.sourceView = topController?.view
					popover.sourceRect = topController?.view.bounds ?? CGRect.zero
				}

				topController?.present(activityViewController, animated: true, completion: nil)
			}
		}
	}

	// Block user functionality
	private func blockUser(blockerId: UUID, blockedId: UUID, reason: String) async {
		do {
			let reportingService = ReportingService()
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

#Preview {
	FriendSearchView(userId: UUID(), displayMode: .allFriends)
}
