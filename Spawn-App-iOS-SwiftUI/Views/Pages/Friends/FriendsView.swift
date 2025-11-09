//
//  FriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-24.
//

import SwiftUI

struct FriendsView: View {
	let user: BaseUserDTO
	@ObservedObject var viewModel: FriendsTabViewModel

	// Deep link parameters
	@Binding var deepLinkedProfileId: UUID?
	@Binding var shouldShowDeepLinkedProfile: Bool
	@State private var isFetchingDeepLinkedProfile = false

	init(
		user: BaseUserDTO, viewModel: FriendsTabViewModel? = nil, deepLinkedProfileId: Binding<UUID?> = .constant(nil),
		shouldShowDeepLinkedProfile: Binding<Bool> = .constant(false)
	) {
		self.user = user
		self._deepLinkedProfileId = deepLinkedProfileId
		self._shouldShowDeepLinkedProfile = shouldShowDeepLinkedProfile

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
			NavigationStack {
				VStack {
					HStack {
						FriendRequestNavButtonView
					}
					.padding(.top, 25)
					.padding(.horizontal, 25)
					FriendsTabView(user: user, viewModel: viewModel)
				}
				.background(universalBackgroundColor)
				.navigationBarHidden(true)
			}
		}
		.task {
			// CRITICAL FIX: Use MainActor task to respect navigation lifecycle
			// Previous implementation used Task.detached which broke automatic cancellation
			// MainActor tasks respect view lifecycle and cancel automatically on disappear
			Task { @MainActor in
				guard !Task.isCancelled else {
					print("⚠️ [NAV] FriendsView: Fetch cancelled before starting")
					return
				}

				await viewModel.fetchIncomingFriendRequests()

				guard !Task.isCancelled else {
					print("⚠️ [NAV] FriendsView: Fetch cancelled after completion")
					return
				}

				print("✅ [NAV] FriendsView: Friend requests loaded")
			}
		}
		.onAppear {
			print("👁️ [NAV] FriendsView appeared")
			// Handle deep link if one is pending when view appears
			if shouldShowDeepLinkedProfile, let profileId = deepLinkedProfileId {
				handleDeepLinkedProfile(profileId)
			}
		}
		.onChange(of: shouldShowDeepLinkedProfile) { _, shouldShow in
			if shouldShow, let profileId = deepLinkedProfileId {
				handleDeepLinkedProfile(profileId)
			}
		}
	}

	// MARK: - Deep Link Handling
	private func handleDeepLinkedProfile(_ profileId: UUID) {
		print("🎯 FriendsView: Handling deep linked profile: \(profileId)")

		guard !isFetchingDeepLinkedProfile else {
			print("⚠️ FriendsView: Already fetching deep linked profile, ignoring")
			return
		}

		isFetchingDeepLinkedProfile = true

		Task {
			do {
				// Fetch the profile from the API
				print("🔄 FriendsView: Fetching profile from API")
				let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: user.id) : APIService()

				guard let url = URL(string: "\(APIService.baseURL)users/\(profileId)") else {
					throw APIError.URLError
				}

				let parameters = [
					"requestingUserId": user.id.uuidString
				]
				let fetchedUser: BaseUserDTO = try await apiService.fetchData(from: url, parameters: parameters)

				print(
					"✅ FriendsView: Successfully fetched deep linked profile: \(fetchedUser.name ?? fetchedUser.username ?? "Unknown")"
				)

				// Navigate to the profile
				await MainActor.run {
					let profileView = ProfileView(user: fetchedUser)

					// Get the current window and present the profile
					if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
						let window = windowScene.windows.first,
						let rootViewController = window.rootViewController
					{

						let hostingController = UIHostingController(rootView: profileView)
						rootViewController.present(hostingController, animated: true)
					}

					// Clean up deep link state
					shouldShowDeepLinkedProfile = false
					deepLinkedProfileId = nil
					isFetchingDeepLinkedProfile = false

					print("🎯 FriendsView: Successfully navigated to profile")
				}

			} catch {
				print("❌ FriendsView: Failed to fetch deep linked profile: \(error)")
				print("❌ FriendsView: Error details - Profile ID: \(profileId), Error: \(error.localizedDescription)")

				await MainActor.run {
					shouldShowDeepLinkedProfile = false
					deepLinkedProfileId = nil
					isFetchingDeepLinkedProfile = false
				}

				// Show error to user via InAppNotificationManager
				await MainActor.run {
					InAppNotificationManager.shared.showNotification(
						title: "Unable to open profile",
						message:
							"The profile you're trying to view might not exist or you might not have permission to view it.",
						type: .error
					)
				}
			}
		}
	}
}

struct BaseFriendNavButtonView: View {
	var iconImageName: String
	var topText: String
	var bottomText: String

	var body: some View {
		HStack {
			VStack {
				HStack {
					Text(topText)
						.onestSubheadline()
						.multilineTextAlignment(.leading)
						.lineLimit(1)
						.fixedSize(horizontal: true, vertical: false)
						.padding(.bottom, 6)
					Spacer()
				}
				HStack {
					Text(bottomText)
						.onestSmallText()
						.multilineTextAlignment(.leading)
						.fixedSize(horizontal: true, vertical: false)
						.lineLimit(1)
					Spacer()
				}
			}
			.font(.caption)
			.foregroundColor(.white)
			.padding(.leading, 8)
			.padding(.vertical, 8)
			Image(iconImageName)
				.resizable()
				.frame(width: 50, height: 50)
		}
		.background(universalSecondaryColor)
		.cornerRadius(12)
	}
}

extension FriendsView {
	var FriendRequestNavButtonView: some View {
		NavigationLink(destination: {
			FriendRequestsView(userId: user.id)
		}) {
			HStack {
				HStack(spacing: 8) {
					Text("Friend Requests")
						.font(Font.custom("Onest", size: 17).weight(.semibold))
						.foregroundColor(.white)

					// Only show red indicator if there are friend requests
					if viewModel.incomingFriendRequests.count > 0 {
						VStack(spacing: 10) {
							Text("\(viewModel.incomingFriendRequests.count)")
								.font(Font.custom("Onest", size: 12).weight(.semibold))
								.lineSpacing(14.40)
								.foregroundColor(.white)
						}
						.padding(EdgeInsets(top: 7, leading: 11, bottom: 7, trailing: 11))
						.frame(width: 20, height: 20)
						.background(Color(hex: figmaSoftBlueHex))
						.cornerRadius(16)
					}
				}

				Spacer()

				Text("View All >")
					.font(Font.custom("Onest", size: 16).weight(.semibold))
					.foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.80))
			}
			.padding(16)
			.background(Color(hex: figmaSoftBlueHex))
			.cornerRadius(12)
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared

	// Create a mock view model with hardcoded data
	let mockViewModel = FriendsTabViewModel(
		userId: BaseUserDTO.danielAgapov.id, apiService: MockAPIService(userId: BaseUserDTO.danielAgapov.id))

	// Add hardcoded friends data
	mockViewModel.friends = [
		FullFriendUserDTO.danielLee,
		FullFriendUserDTO(
			id: UUID(),
			username: "sarah_dev",
			profilePicture: "Haley_pfp",
			name: "Sarah Johnson",
			bio: "Software engineer who loves hiking and coffee",
			email: "sarah.johnson@example.com"
		),
		FullFriendUserDTO(
			id: UUID(),
			username: "mike_fitness",
			profilePicture: "Daniel_Agapov_pfp",
			name: "Mike Chen",
			bio: "Fitness enthusiast and basketball player",
			email: "mike.chen@example.com"
		),
		FullFriendUserDTO(
			id: UUID(),
			username: "emma_artist",
			profilePicture: "Daniel_Lee_pfp",
			name: "Emma Wilson",
			bio: "Digital artist and UI/UX designer",
			email: "emma.wilson@example.com"
		),
		FullFriendUserDTO(
			id: UUID(),
			username: "alex_gamer",
			profilePicture: "Haley_pfp",
			name: "Alex Rodriguez",
			bio: "Gaming enthusiast and tech blogger",
			email: "alex.rodriguez@example.com"
		),
	]

	// Add hardcoded recommended friends data
	mockViewModel.recommendedFriends = [
		RecommendedFriendUserDTO.haley,
		RecommendedFriendUserDTO(
			id: UUID(),
			username: "jake_music",
			profilePicture: "Daniel_Agapov_pfp",
			name: "Jake Thompson",
			bio: "Musician and music producer",
			email: "jake.thompson@example.com",
			mutualFriendCount: 3,
			sharedActivitiesCount: 1
		),
		RecommendedFriendUserDTO(
			id: UUID(),
			username: "lily_chef",
			profilePicture: "Daniel_Lee_pfp",
			name: "Lily Park",
			bio: "Professional chef and food blogger",
			email: "lily.park@example.com",
			mutualFriendCount: 2,
			sharedActivitiesCount: 4
		),
		RecommendedFriendUserDTO(
			id: UUID(),
			username: "tom_traveler",
			profilePicture: "Haley_pfp",
			name: "Tom Anderson",
			bio: "Travel photographer and adventure seeker",
			email: "tom.anderson@example.com",
			mutualFriendCount: 1,
			sharedActivitiesCount: 2
		),
		RecommendedFriendUserDTO(
			id: UUID(),
			username: "nina_writer",
			profilePicture: "Daniel_Agapov_pfp",
			name: "Nina Martinez",
			bio: "Writer and book club organizer",
			email: "nina.martinez@example.com",
			mutualFriendCount: 4,
			sharedActivitiesCount: 0
		),
	]

	// Set filtered lists to show the data
	mockViewModel.filteredFriends = mockViewModel.friends
	mockViewModel.filteredRecommendedFriends = mockViewModel.recommendedFriends

	// Add some incoming friend requests for the notification badge
	mockViewModel.incomingFriendRequests = [
		FetchFriendRequestDTO(
			id: UUID(),
			senderUser: BaseUserDTO(
				id: UUID(),
				username: "new_friend1",
				profilePicture: "Daniel_Lee_pfp",
				name: "Chris Davis",
				bio: "New to the area, looking to make friends!",
				email: "chris.davis@example.com"
			),
			mutualFriendCount: 1
		),
		FetchFriendRequestDTO(
			id: UUID(),
			senderUser: BaseUserDTO(
				id: UUID(),
				username: "new_friend2",
				profilePicture: "Haley_pfp",
				name: "Maya Patel",
				bio: "Love outdoor activities and board games",
				email: "maya.patel@example.com"
			),
			mutualFriendCount: 2
		),
	]

	return FriendsView(user: .danielAgapov, viewModel: mockViewModel)
		.environmentObject(appCache)
}
