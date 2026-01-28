//
//  FriendRequestsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-17.
//

import SwiftUI

struct FriendRequestsView: View {
	@Environment(\.dismiss) private var dismiss
	@State private var viewModel: FriendRequestsViewModel
	@State private var showSuccessDrawer = false
	@State private var acceptedFriend: BaseUserDTO?
	@State private var navigateToAddToActivityType = false

	private let isPreviewMode: Bool

	init(userId: UUID, viewModel: FriendRequestsViewModel? = nil) {
		if let existingViewModel = viewModel {
			self._viewModel = State(wrappedValue: existingViewModel)
			self.isPreviewMode = true  // When a viewModel is provided, we're in preview mode
		} else {
			self._viewModel = State(wrappedValue: FriendRequestsViewModel(userId: userId))
			self.isPreviewMode = false
		}
	}

	var body: some View {
		VStack(spacing: 0) {
			headerView
			contentView
			Spacer()
		}
		.background(universalBackgroundColor)
		.navigationBarHidden(true)
		.task {
			// Only fetch data from API if we're not in preview mode
			if !isPreviewMode {
				await viewModel.fetchFriendRequests()
			}
		}
		.overlay(successDrawerOverlay)
		.onChange(of: showSuccessDrawer) { _, isPresented in
			if !isPresented && !isPreviewMode {
				Task { await viewModel.fetchFriendRequests() }
			}
		}
		.navigationDestination(isPresented: $navigateToAddToActivityType) {
			if let friend = acceptedFriend {
				AddToActivityTypeView(user: friend)
			}
		}
		.userProfileNavigationDestination()
	}

	// MARK: - Header View
	private var headerView: some View {
		HStack {
			Button(action: {
				dismiss()
			}) {
				Image(systemName: "chevron.left")
					.font(.title3)
					.foregroundColor(universalAccentColor)
			}

			Spacer()

			Text("Friend Requests")
				.font(.title3)
				.fontWeight(.semibold)

			Spacer()

			// Empty view to balance the back button
			Image(systemName: "chevron.left")
				.font(.title3)
				.foregroundColor(.clear)
		}
		.padding(.vertical, 25)
		.padding(.horizontal, 25)
	}

	// MARK: - Content View
	private var contentView: some View {
		ScrollView {
			VStack(spacing: 0) {
				if viewModel.isLoading {
					loadingView
				} else if viewModel.incomingFriendRequests.isEmpty && viewModel.sentFriendRequests.isEmpty {
					emptyStateView
				} else {
					friendRequestsContent
				}
			}
		}
	}

	// MARK: - Loading View
	private var loadingView: some View {
		ProgressView()
			.padding(.top, 40)
	}

	// MARK: - Empty State View
	private var emptyStateView: some View {
		Text("No friend requests")
			.foregroundColor(.gray)
			.padding(.top, 40)
	}

	// MARK: - Friend Requests Content
	private var friendRequestsContent: some View {
		VStack(spacing: 0) {
			incomingFriendRequestsSection
			sectionDivider
			sentFriendRequestsSection
		}
	}

	// MARK: - Incoming Friend Requests Section
	private var incomingFriendRequestsSection: some View {
		Group {
			if !viewModel.incomingFriendRequests.isEmpty {
				VStack(spacing: 0) {
					HStack {
						Text("Received")
							.font(.onestMedium(size: 16))
							.foregroundColor(universalPlaceHolderTextColor)
						Spacer()
					}
					.padding(.bottom, 8)
					.padding(.horizontal, 25)

					ForEach(viewModel.incomingFriendRequests) { request in
						FriendRequestItemView(
							friendRequest: request,
							isIncoming: true,
							onAccept: {
								handleAcceptRequest(request)
							},
							onRemove: {
								handleDeclineRequest(request)
							}
						)
						.padding(.vertical, 8)
						.padding(.leading, 20)
						.padding(.trailing, 25)

					}
				}
			}
		}
	}

	// MARK: - Section Divider
	private var sectionDivider: some View {
		Group {
			if !viewModel.incomingFriendRequests.isEmpty && !viewModel.sentFriendRequests.isEmpty {
				Divider()
					.background(universalPlaceHolderTextColor)
					.padding(.vertical, 16)
					.padding(.horizontal, 20)
			}
		}
	}

	// MARK: - Sent Friend Requests Section
	private var sentFriendRequestsSection: some View {
		Group {
			if !viewModel.sentFriendRequests.isEmpty {
				VStack(spacing: 0) {
					HStack {
						Text("Sent")
							.font(.onestMedium(size: 16))
							.foregroundColor(universalAccentColor)
						Spacer()
					}
					.padding(.horizontal, 25)
					.padding(.bottom, 8)

					ForEach(viewModel.sentFriendRequests) { request in
						SentFriendRequestItemView(
							friendRequest: request,
							onRemove: {
								handleCancelSentRequest(request)
							}
						)
						.padding(.vertical, 8)
						.padding(.leading, 20)
						.padding(.trailing, 25)
					}
				}
			}
		}
	}

	// MARK: - Success Drawer Overlay
	private var successDrawerOverlay: some View {
		Group {
			if showSuccessDrawer, let friend = acceptedFriend {
				FriendRequestSuccessDrawer(
					friendUser: friend,
					isPresented: $showSuccessDrawer,
					onAddToActivityType: {
						navigateToAddToActivityType = true
					}
				)
			}
		}
	}

	// MARK: - Helper Methods
	private func handleAcceptRequest(_ request: FetchFriendRequestDTO) {
		// Set acceptedFriend BEFORE calling respondToFriendRequest
		// because that method immediately removes the request from the array
		acceptedFriend = request.senderUser
		Task {
			await viewModel.respondToFriendRequest(requestId: request.id, action: .accept)
			// Show success drawer after successful acceptance
			showSuccessDrawer = true
		}
	}

	private func handleDeclineRequest(_ request: FetchFriendRequestDTO) {
		Task {
			await viewModel.respondToFriendRequest(requestId: request.id, action: .decline)
		}
	}

	private func handleCancelSentRequest(_ request: FetchSentFriendRequestDTO) {
		Task {
			await viewModel.respondToFriendRequest(requestId: request.id, action: .cancel)
		}
	}
}

// MARK: - Preview
@available(iOS 17.0, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared

	// Create a mock view model with pre-populated data (following FriendsView pattern)
	let mockUserId = UUID()
	let mockViewModel = FriendRequestsViewModel(userId: mockUserId)

	// Pre-populate incoming friend requests
	mockViewModel.incomingFriendRequests = [
		FetchFriendRequestDTO(
			id: UUID(),
			senderUser: BaseUserDTO(
				id: UUID(),
				username: "emma_artist",
				profilePicture: "Daniel_Lee_pfp",
				name: "Emma Wilson",
				bio: "Digital artist and UI/UX designer",
				email: "emma.wilson@example.com"
			),
			mutualFriendCount: 3
		),
		FetchFriendRequestDTO(
			id: UUID(),
			senderUser: BaseUserDTO(
				id: UUID(),
				username: "mike_fitness",
				profilePicture: "Daniel_Agapov_pfp",
				name: "Mike Chen",
				bio: "Fitness enthusiast and basketball player",
				email: "mike.chen@example.com"
			),
			mutualFriendCount: 1
		),
		FetchFriendRequestDTO(
			id: UUID(),
			senderUser: BaseUserDTO(
				id: UUID(),
				username: "alex_gamer",
				profilePicture: "Haley_pfp",
				name: "Alex Rodriguez",
				bio: "Gaming enthusiast and tech blogger",
				email: "alex.rodriguez@example.com"
			),
			mutualFriendCount: 2
		),
	]

	// Pre-populate sent friend requests
	mockViewModel.sentFriendRequests = [
		FetchSentFriendRequestDTO(
			id: UUID(),
			receiverUser: BaseUserDTO(
				id: UUID(),
				username: "sarah_dev",
				profilePicture: "Haley_pfp",
				name: "Sarah Johnson",
				bio: "Software engineer who loves hiking and coffee",
				email: "sarah.johnson@example.com"
			)
		),
		FetchSentFriendRequestDTO(
			id: UUID(),
			receiverUser: BaseUserDTO(
				id: UUID(),
				username: "jake_music",
				profilePicture: "Daniel_Lee_pfp",
				name: "Jake Thompson",
				bio: "Musician and music producer",
				email: "jake.thompson@example.com"
			)
		),
	]

	// Use the actual FriendRequestsView with mock view model (just like FriendsView does)
	return NavigationStack {
		FriendRequestsView(userId: mockUserId, viewModel: mockViewModel)
	}.environmentObject(appCache)
}
