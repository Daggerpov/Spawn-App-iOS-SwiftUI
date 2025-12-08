//
//  ContentView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 4/19/25.
//

import SwiftUI

struct ContentView: View {
	var user: BaseUserDTO
	@State private var selectedTabsEnum: Tabs = .home
	// CRITICAL FIX: Use optional ViewModels to prevent unnecessary re-initialization
	// With @Observable, SwiftUI may recreate the view struct frequently (e.g., when parent state changes).
	// If we initialize ViewModels in init(), their init() runs every time even though @State
	// only uses the first instance. This causes side effects like setting up Combine subscriptions,
	// NotificationCenter observers, and timers to run repeatedly.
	// By making them optional and initializing in .task, we ensure init() only runs once.
	@State private var friendsViewModel: FriendsTabViewModel?
	@State private var feedViewModel: FeedViewModel?
	private var tutorialViewModel = TutorialViewModel.shared
	@ObservedObject private var inAppNotificationManager = InAppNotificationManager.shared
	@ObservedObject var deepLinkManager: DeepLinkManager

	// Computed binding to convert Tabs <-> TabType for child views
	private var selectedTabBinding: Binding<TabType> {
		Binding(
			get: { selectedTabsEnum.toTabType },
			set: { selectedTabsEnum = Tabs(from: $0) }
		)
	}

	// Deep link state
	@State private var shouldShowDeepLinkedActivity = false
	@State private var deepLinkedActivityId: UUID?
	@State private var shouldShowDeepLinkedProfile = false
	@State private var deepLinkedProfileId: UUID?

	// Global activity popup state
	@State private var showingGlobalActivityPopup = false
	@State private var globalPopupActivity: FullFeedActivityDTO?
	@State private var globalPopupColor: Color?
	@State private var globalPopupFromMapView = false

	// Store background refresh task so we can cancel it on disappear
	@State private var backgroundRefreshTask: Task<Void, Never>?

	// ProfileViewModel for MyProfileView - owned here to prevent recreation
	@State private var profileViewModel: ProfileViewModel?

	init(user: BaseUserDTO, deepLinkManager: DeepLinkManager = DeepLinkManager.shared) {
		self.user = user
		self.deepLinkManager = deepLinkManager
		// CRITICAL: Do NOT initialize ViewModels here.
		// ViewModels are initialized lazily in .task to prevent repeated init() calls
		// when SwiftUI recreates this view struct.
	}

	var body: some View {
		ZStack {
			// Show loading state while ViewModels are being initialized
			if let feedVM = feedViewModel, let friendsVM = friendsViewModel, let profileVM = profileViewModel {
				WithTabBarBinding(selection: $selectedTabsEnum) { selectedTab in
					switch selectedTab {
					case .home:
						ActivityFeedView(
							user: user,
							viewModel: feedVM,
							selectedTab: selectedTabBinding,
							deepLinkedActivityId: $deepLinkedActivityId,
							shouldShowDeepLinkedActivity: $shouldShowDeepLinkedActivity
						)
					case .map:
						MapView(user: user, viewModel: feedVM)
							.id("MapView-\(user.id)")  // Stable identity prevents recreation
							.disabled(tutorialViewModel.tutorialState.shouldRestrictNavigation)
					case .activities:
						ActivityCreationView(
							creatingUser: user,
							closeCallback: {
								// Navigate back to home tab when closing
								selectedTabsEnum = .home
							},
							selectedTab: selectedTabBinding
						)
					case .friends:
						FriendsView(
							user: user,
							viewModel: friendsVM,
							deepLinkedProfileId: $deepLinkedProfileId,
							shouldShowDeepLinkedProfile: $shouldShowDeepLinkedProfile
						)
						.disabled(tutorialViewModel.tutorialState.shouldRestrictNavigation)
					case .profile:
						NavigationStack {
							MyProfileView(user: user, profileViewModel: profileVM)
						}
						.disabled(tutorialViewModel.tutorialState.shouldRestrictNavigation)
					}
				}
			} else {
				// Minimal loading state while ViewModels initialize
				Color.clear
			}
		}
		.task {
			// CRITICAL FIX: Initialize ViewModels lazily in .task to prevent repeated init() calls.
			// This runs only once when the view appears, not on every view struct recreation.
			if feedViewModel == nil {
				feedViewModel = FeedViewModel(userId: user.id)
			}
			if friendsViewModel == nil {
				friendsViewModel = FriendsTabViewModel(userId: user.id)
			}
			if profileViewModel == nil {
				profileViewModel = ProfileViewModel(userId: user.id)
			}

			// CRITICAL FIX: Load cached activities immediately to unblock UI
			// This ensures both ActivityFeedView and MapView have data instantly
			guard let feedVM = feedViewModel else { return }

			// Load cached data through view model instead of directly accessing cache
			await MainActor.run {
				feedVM.loadCachedActivities()
			}

			// Check if task was cancelled before starting background refresh
			if Task.isCancelled {
				return
			}

			// Refresh from API in background (non-blocking)
			// CRITICAL: Always run in background, even if cache is empty, to avoid blocking UI
			// Run on MainActor to ensure proper sequencing with view updates
			backgroundRefreshTask = Task { @MainActor in
				guard !Task.isCancelled else {
					return
				}

				await feedVM.fetchAllData()
			}
		}
		.onAppear {
			// Resume timers when view appears
			feedViewModel?.resumeTimers()

			// Configure tab bar appearance for theme compatibility
			let appearance = UITabBarAppearance()
			appearance.configureWithOpaqueBackground()
			appearance.backgroundColor = UIColor { traitCollection in
				switch traitCollection.userInterfaceStyle {
				case .dark:
					return UIColor.systemBackground.withAlphaComponent(0.9)
				default:
					return UIColor.systemBackground.withAlphaComponent(0.9)
				}
			}

			UITabBar.appearance().standardAppearance = appearance
			UITabBar.appearance().scrollEdgeAppearance = appearance
			UITabBar.appearance().unselectedItemTintColor = UIColor { traitCollection in
				switch traitCollection.userInterfaceStyle {
				case .dark:
					return UIColor.label
				default:
					return UIColor.label
				}
			}

			// Fetch friend requests to show badge count
			if let friendsVM = friendsViewModel {
				Task {
					await friendsVM.fetchIncomingFriendRequests()
				}
			}
		}
		.onDisappear {
			// Pause timers to save resources when view is not visible
			feedViewModel?.pauseTimers()

			// Cancel any ongoing background refresh to prevent blocking
			backgroundRefreshTask?.cancel()
			backgroundRefreshTask = nil
		}
		.onChange(of: deepLinkManager.shouldShowActivity) { _, shouldShow in
			if shouldShow, let activityId = deepLinkManager.activityToShow {
				handleDeepLinkActivity(activityId)
			}
		}
		.onChange(of: deepLinkManager.shouldShowProfile) { _, shouldShow in
			if shouldShow, let profileId = deepLinkManager.profileToShow {
				handleDeepLinkProfile(profileId)
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .deepLinkActivityReceived)) { notification in
			if let activityId = notification.userInfo?["activityId"] as? UUID {
				handleDeepLinkActivity(activityId)
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .deepLinkProfileReceived)) { notification in
			if let profileId = notification.userInfo?["profileId"] as? UUID {
				handleDeepLinkProfile(profileId)
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowActivityFullAlert"))) {
			notification in
			if let message = notification.userInfo?["message"] as? String {
				inAppNotificationManager.showNotification(
					title: "Activity Full",
					message: message,
					type: .error,
					duration: 4.0
				)
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .showGlobalActivityPopup)) { notification in
			if let activity = notification.userInfo?["activity"] as? FullFeedActivityDTO,
				let color = notification.userInfo?["color"] as? Color
			{
				globalPopupActivity = activity
				globalPopupColor = color
				globalPopupFromMapView = notification.userInfo?["fromMapView"] as? Bool ?? false
				showingGlobalActivityPopup = true
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .activityUpdated)) { notification in
			// Update the global popup activity if it's currently being displayed and matches the updated activity
			if let updatedActivity = notification.object as? FullFeedActivityDTO,
				let currentActivity = globalPopupActivity,
				updatedActivity.id == currentActivity.id,
				showingGlobalActivityPopup
			{
				print("🔄 ContentView: Updating global popup activity for \(updatedActivity.title ?? "Unknown")")
				globalPopupActivity = updatedActivity
			}
		}

		// In-app notification overlay
		VStack {
			if inAppNotificationManager.isShowingNotification,
				let notification = inAppNotificationManager.currentNotification
			{
				InAppNotificationView(
					title: notification.title,
					message: notification.message,
					notificationType: notification.type,
					onDismiss: {
						inAppNotificationManager.dismissNotification()
					}
				)
				.padding(.horizontal, 16)
				.padding(.top, 8)
				.transition(.move(edge: .top).combined(with: .opacity))
				.zIndex(1000)
			}

			Spacer()
		}

		// Global activity popup overlay - covers entire screen including tab bar
		if showingGlobalActivityPopup, let activity = globalPopupActivity, let color = globalPopupColor {
			ActivityPopupDrawer(
				activity: activity,
				activityColor: color,
				isPresented: $showingGlobalActivityPopup,
				selectedTab: Binding<TabType?>(
					get: { selectedTabsEnum.toTabType },
					set: { if let newTab = $0 { selectedTabsEnum = Tabs(from: newTab) } }
				),
				fromMapView: globalPopupFromMapView
			)
			.id(
				"\(activity.id.uuidString)-\(activity.title ?? "untitled")-\(activity.icon ?? "")-\(activity.participantUsers?.count ?? 0)"
			)  // Force recreation when activity changes
			.allowsHitTesting(true)
			.ignoresSafeArea(.all, edges: .all)  // Cover absolutely everything
			.zIndex(999)  // Below notifications but above everything else
		}
	}

	// MARK: - Deep Link Handling
	private func handleDeepLinkActivity(_ activityId: UUID) {
		print("🎯 ContentView: Handling deep link for activity: \(activityId)")

		// Register user as invited to this activity if authenticated
		if UserAuthViewModel.shared.isLoggedIn {
			registerUserAsInvitedToActivity(activityId)
		}

		// Switch to home tab to show the activity in feed
		selectedTabsEnum = .home

		// Add a small delay to ensure tab switching completes before setting deep link state
		Task { @MainActor in
			try? await Task.sleep(for: .seconds(0.1))
			// Set up the deep linked activity state
			deepLinkedActivityId = activityId
			shouldShowDeepLinkedActivity = true

			print(
				"🎯 ContentView: Set deep link state - activityId: \(activityId), shouldShow: \(shouldShowDeepLinkedActivity)"
			)
		}

		// Clear the deep link manager state
		deepLinkManager.clearPendingDeepLink()
	}

	private func registerUserAsInvitedToActivity(_ activityId: UUID) {
		guard let currentUser = UserAuthViewModel.shared.spawnUser else {
			print("❌ ContentView: Cannot register invitation - user not authenticated")
			return
		}

		print("🎯 ContentView: Registering user \(currentUser.id) as invited to activity \(activityId)")

		// Call backend API to register the user as invited to this activity
		Task {
			do {
				let url = URL(
					string:
						"\(ServiceConstants.URLs.apiBase)activities/\(activityId.uuidString)/invite/\(currentUser.id.uuidString)"
				)!

				var request = URLRequest(url: url)
				request.httpMethod = "POST"
				request.setValue("application/json", forHTTPHeaderField: "Content-Type")

				let (_, response) = try await URLSession.shared.data(for: request)

				if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
					// Show success notification
					Task { @MainActor in
						InAppNotificationManager.shared.showNotification(
							title: "You're invited!",
							message: "You've been added to this activity. Check it out!",
							type: .success,
							duration: 4.0
						)
					}
				} else {
					print(
						"❌ ContentView: Failed to register user as invited - HTTP \(String(describing: (response as? HTTPURLResponse)?.statusCode))"
					)
				}
			} catch {
				print("❌ ContentView: Error registering user as invited: \(error)")
			}
		}
	}

	private func handleDeepLinkProfile(_ profileId: UUID) {
		print("🎯 ContentView: Handling deep link for profile: \(profileId)")

		// Switch to friends tab to show the profile
		selectedTabsEnum = .friends

		// Add a small delay to ensure tab switching completes before setting deep link state
		Task { @MainActor in
			try? await Task.sleep(for: .seconds(0.1))
			// Set up the deep linked profile state
			deepLinkedProfileId = profileId
			shouldShowDeepLinkedProfile = true

			print(
				"🎯 ContentView: Set deep link state - profileId: \(profileId), shouldShow: \(shouldShowDeepLinkedProfile)"
			)
		}

		// Clear the deep link manager state
		deepLinkManager.clearPendingDeepLink()
	}
}

@available(iOS 17.0, *)
#Preview {
	ContentView(user: BaseUserDTO.danielAgapov)
}

func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
	let size = image.size

	// Calculate the scaling factor to fit the image to the target dimensions while maintaining the aspect ratio
	let widthRatio = targetSize.width / size.width
	let heightRatio = targetSize.height / size.height
	let ratio = min(widthRatio, heightRatio)

	let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
	// Add padding by using a percentage of the available space (e.g., 40% from top, 60% from bottom)
	let paddingFactor = 0.9
	let yOffset = (targetSize.height - newSize.height) * paddingFactor

	//Create a new image context
	let renderer = UIGraphicsImageRenderer(size: targetSize)
	let newImage = renderer.image { context in
		// Fill the background with a transparent color
		context.cgContext.setFillColor(UIColor.clear.cgColor)
		context.cgContext.fill(CGRect(origin: .zero, size: targetSize))

		// draw new image
		image.draw(
			in: CGRect(
				x: 0,
				y: yOffset,
				width: newSize.width,
				height: newSize.height
			)
		)
	}

	return newImage
}
