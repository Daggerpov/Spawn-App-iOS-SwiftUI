//
//  ProfileView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import PhotosUI
import SwiftUI

struct ProfileView: View {
	let user: Nameable
	@State private var username: String
	@State private var name: String
	@State private var editingState: ProfileEditText = .edit
	@State private var selectedImage: UIImage?
	@State private var showImagePicker: Bool = false
	@State private var isImageLoading: Bool = false
	@State private var showNotification: Bool = false
	@State private var notificationMessage: String = ""
	@State private var newInterest: String = ""
	@State private var whatsappLink: String = ""
	@State private var instagramLink: String = ""
	@State private var currentMonth = Calendar.current.component(
		.month,
		from: Date()
	)
	@State private var currentYear = Calendar.current.component(
		.year,
		from: Date()
	)
	@State private var refreshFlag = false
	@State private var showCalendarPopup: Bool = false
	@State private var navigateToCalendar: Bool = false
	@State private var showActivityDetails: Bool = false
	@State private var navigateToDayActivities: Bool = false
	@State private var selectedDayActivities: [CalendarActivityDTO] = []
	    	@State private var showReportDialog: Bool = false
	@State private var showBlockDialog: Bool = false
    @State private var blockReason: String = ""
	@State private var showRemoveFriendConfirmation: Bool = false
	@State private var showProfileMenu: Bool = false
	@State private var showAddToActivityType: Bool = false
	@State private var showSuccessDrawer: Bool = false
	@State private var navigateToAddToActivityType: Bool = false
	@State private var showProfileShareSheet: Bool = false
	
	// Store background refresh tasks so we can cancel them on disappear
	@State private var backgroundProfilePictureTask: Task<Void, Never>?
	@State private var backgroundDataLoadTask: Task<Void, Never>?
	
	// Animation states for 3D effects
	@State private var addFriendPressed = false
	@State private var addFriendScale: CGFloat = 1.0
	@State private var acceptButtonPressed = false
	@State private var acceptButtonScale: CGFloat = 1.0
	@State private var denyButtonPressed = false
	@State private var denyButtonScale: CGFloat = 1.0

	@ObservedObject var userAuth = UserAuthViewModel.shared
	@StateObject var profileViewModel = ProfileViewModel()

	// Add environment object for navigation
	@Environment(\.presentationMode) var presentationMode

	// For the back button
	@State private var showBackButton: Bool = false


	// Check if this is the current user's profile
	private var isCurrentUserProfile: Bool {
		if MockAPIService.isMocking {
			return true
		}
		guard let currentUser = userAuth.spawnUser else { return false }
		return currentUser.id == user.id
	}

	init(user: Nameable) {
		self.user = user
		self._profileViewModel = StateObject(
			wrappedValue: ProfileViewModel(userId: user.id)
		)
		self.username = user.username ?? ""
		self.name = user.name ?? ""
	}

	var body: some View {
		profileContent
			.background(universalBackgroundColor.ignoresSafeArea())
			.background(universalBackgroundColor)
		.onChange(of: editingState) { _, newState in
			switch newState {
			case .save:
				// Save original interests when entering edit mode
				profileViewModel.saveOriginalInterests()
			case .edit:
				// This handles the case where editingState transitions back to .edit
				// The cancel button should handle the restoration manually
				break
			}
		}
		.alert(item: $userAuth.activeAlert) { alertType in
			switch alertType {
			case .deleteConfirmation:
				return Alert(
					title: Text("Delete Account"),
					message: Text(
						"Are you sure you want to delete your account? This action cannot be undone."
					),
					primaryButton: .destructive(Text("Delete")) {
						Task {
							await userAuth.deleteAccount()
						}
					},
					secondaryButton: .cancel()
				)
			case .deleteSuccess:
				return Alert(
					title: Text("Account Deleted"),
					message: Text(
						"Your account has been successfully deleted."
					),
					dismissButton: .default(Text("OK")) {
						userAuth.signOut()
					}
				)
			case .deleteError:
				return Alert(
					title: Text("Error"),
					message: Text(
						"Failed to delete your account. Please try again later."
					),
					dismissButton: .default(Text("OK"))
				)
			}
		}
		.onAppear {
			// Update local state from userAuth.spawnUser when view appears
			refreshUserData()
		}
		.task {
			print("📍 [NAV] ProfileView .task started for user \(user.id)")
			let taskStartTime = Date()
			
			// Check if task was cancelled (user navigated away)
			if Task.isCancelled {
				print("⚠️ [NAV] Task cancelled before loading profile data - user navigated away")
				return
			}
			
			// CRITICAL FIX: Load profile data in background to avoid blocking navigation
			// Profile picture can use cached version immediately
			if let profilePictureUrl = user.profilePicture {
				backgroundProfilePictureTask = Task.detached(priority: .background) {
					let profilePictureCache = ProfilePictureCache.shared
					_ = await profilePictureCache.getCachedImageWithRefresh(
						for: user.id,
						from: profilePictureUrl,
						maxAge: 6 * 60 * 60 // 6 hours
					)
				}
			}
			
			// Set back button state immediately (no async needed)
			if !isCurrentUserProfile {
				showBackButton = true
			}
			
			let setupDuration = Date().timeIntervalSince(taskStartTime)
			print("⏱️ [NAV] ProfileView initial setup in \(String(format: "%.3f", setupDuration))s")
			
			// Check if task was cancelled before starting background data load
			if Task.isCancelled {
				print("⚠️ [NAV] Task cancelled before starting background data load - user navigated away")
				return
			}
			
			// Load all profile data in background (non-blocking)
			print("🔄 [NAV] ProfileView loading profile data in background")
			backgroundDataLoadTask = Task.detached(priority: .userInitiated) {
				let dataLoadStart = Date()
				
				// Load profile data
				await profileViewModel.loadAllProfileData(userId: user.id)
				
				// Initialize social media links
				if let socialMedia = await profileViewModel.userSocialMedia {
					await MainActor.run {
						whatsappLink = socialMedia.whatsappLink ?? ""
						instagramLink = socialMedia.instagramLink ?? ""
					}
				}

				// Check friendship status if not viewing own profile
				if !isCurrentUserProfile,
					let currentUserId = await userAuth.spawnUser?.id
				{
					// Check if user is a RecommendedFriendUserDTO with relationship status
					if let recommendedFriend = user as? RecommendedFriendUserDTO,
					   recommendedFriend.relationshipStatus != nil {
						// Use the relationship status from the DTO - no API call needed
						await MainActor.run {
							profileViewModel.setFriendshipStatusFromRecommendedFriend(recommendedFriend)
						}
					} else {
						// For other user types (BaseUserDTO, etc.), use the original API call
						await profileViewModel.checkFriendshipStatus(
							currentUserId: currentUserId,
							profileUserId: user.id
						)
					}

					// If they're friends, fetch their activities
					if await profileViewModel.friendshipStatus == .friends {
						await profileViewModel.fetchProfileActivities(
							profileUserId: user.id
						)
					}
				}
				
				let dataLoadDuration = Date().timeIntervalSince(dataLoadStart)
				print("✅ [NAV] ProfileView background data load completed in \(String(format: "%.2f", dataLoadDuration))s")
			}
		}
		.onAppear {
			print("👁️ [NAV] ProfileView appeared for user \(user.id)")
		}
		.onDisappear {
			print("👋 [NAV] ProfileView disappearing - cancelling background tasks")
			// Cancel any ongoing background tasks to prevent blocking
			backgroundProfilePictureTask?.cancel()
			backgroundProfilePictureTask = nil
			backgroundDataLoadTask?.cancel()
			backgroundDataLoadTask = nil
			print("👋 [NAV] ProfileView disappeared")
		}
		.onChange(of: userAuth.spawnUser) { _, newUser in
			// Update local state whenever spawnUser changes
			refreshUserData()
		}
		.onChange(of: profileViewModel.userSocialMedia) { _, newSocialMedia in
			// Update local state when social media changes
			if let socialMedia = newSocialMedia {
				whatsappLink = socialMedia.whatsappLink ?? ""
				instagramLink = socialMedia.instagramLink ?? ""
			}
		}
		.onChange(of: profileViewModel.friendshipStatus) { _, newStatus in
			// Fetch activities when friendship status changes to friends
			if newStatus == .friends {
				Task {
					await profileViewModel.fetchProfileActivities(
						profileUserId: user.id
					)
				}
			}
		}
		.onChange(of: navigateToDayActivities) { _, newValue in
			if newValue {
				// Ensure navigation happens on main thread
				DispatchQueue.main.async {
					// Navigation logic handled by the view
				}
			}
		}
		// Add a timer to periodically refresh data
		.onReceive(
			Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
		) { _ in
			refreshUserData()
			refreshFlag.toggle()  // Force the view to update
		}
		.accentColor(universalAccentColor)
		.toast(
			isShowing: $showNotification,
			message: notificationMessage,
			duration: 5.0
		)
	}

	// Main content broken into a separate computed property to reduce complexity
	private var profileContent: some View {
		NavigationStack {
			profileWithOverlay
				.modifier(ImagePickerModifier(
					showImagePicker: $showImagePicker,
					selectedImage: $selectedImage,
					isImageLoading: $isImageLoading
				))
				.modifier(SheetsAndAlertsModifier(
					showActivityDetails: $showActivityDetails,
					activityDetailsView: AnyView(activityDetailsView),
					showRemoveFriendConfirmation: $showRemoveFriendConfirmation,
					removeFriendConfirmationAlert: AnyView(removeFriendConfirmationAlert),
					showReportDialog: $showReportDialog,
					reportUserDrawer: AnyView(reportUserDrawer),
					showBlockDialog: $showBlockDialog,
					blockUserAlert: AnyView(blockUserAlert),
					showProfileMenu: $showProfileMenu,
					profileMenuSheet: AnyView(profileMenuSheet)
				))
				.onTapGesture {
					// Dismiss profile menu if it's showing
					if showProfileMenu {
						showProfileMenu = false
					}
				}
				.background(universalBackgroundColor)
		}
	}

	private var profileWithOverlay: some View {
		ZStack {
			universalBackgroundColor.ignoresSafeArea()
			
			VStack {
				profileInnerComponentsView
					.padding(.horizontal)
			}
			.navigationBarBackButtonHidden(true)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					if showBackButton {
						Button(action: {
							presentationMode.wrappedValue.dismiss()
						}) {
							HStack(spacing: 4) {
								Image(systemName: "chevron.left")
								Text("Back")
							}
							.foregroundColor(universalAccentColor)
						}
					}
				}

				ToolbarItem(placement: .principal) {
					// Header text removed for other users' profiles
					EmptyView()
				}

				// Add appropriate trailing button based on user profile type
				ToolbarItem(placement: .navigationBarTrailing) {
					if isCurrentUserProfile {
						// Settings button for current user profile
						NavigationLink(destination: SettingsView()) {
							Image(systemName: "gearshape")
								.foregroundColor(universalAccentColor)
						}
					} else {
						// Menu button for other user profiles - always show immediately
						Button(action: {
							showProfileMenu = true
						}) {
							Image(systemName: "ellipsis")
								.foregroundColor(universalAccentColor)
						}
					}
				}
			}
			.navigationDestination(isPresented: $showAddToActivityType) {
				AddToActivityTypeView(user: user)
			}
			.navigationDestination(isPresented: $navigateToAddToActivityType) {
				AddToActivityTypeView(user: user)
			}
			.navigationDestination(isPresented: $navigateToCalendar) {
				calendarFullScreenView
			}
			.navigationDestination(isPresented: $navigateToDayActivities) {
				dayActivitiesPageView
			}

			// Overlay for profile menu
			profileMenuOverlay
			
			// Success drawer overlay
			if showSuccessDrawer {
				FriendRequestSuccessDrawer(
					friendUser: user as! BaseUserDTO,
					isPresented: $showSuccessDrawer,
					onAddToActivityType: {
						navigateToAddToActivityType = true
					}
				)
			}
			
			// Profile share drawer overlay
			if showProfileShareSheet {
				ProfileShareDrawer(
					user: user,
					showShareSheet: $showProfileShareSheet
				)
			}
		}
	}

	private var profileInnerComponentsView: some View {
		VStack(alignment: .center, spacing: 10) {
			// Profile Header (Profile Picture + Name)
			ProfileHeaderView(
				user: user,
				selectedImage: $selectedImage,
				showImagePicker: $showImagePicker,
				isImageLoading: $isImageLoading,
				refreshFlag: $refreshFlag,
				editingState: $editingState
			)

			// Friendship badge (for other users' profiles)
			friendshipBadge

			// Friend Request Buttons (for incoming requests)
			if !isCurrentUserProfile && profileViewModel.friendshipStatus == .requestReceived {
				HStack(spacing: 10) {
					Button(action: {
						if let requestId = profileViewModel.pendingFriendRequestId {
							Task {
								await profileViewModel.acceptFriendRequest(requestId: requestId)
								// Show success drawer after successful acceptance
								showSuccessDrawer = true
							}
						}
					}) {
						HStack(spacing: 6) {
							Image(systemName: "checkmark")
								.font(.system(size: 14, weight: .semibold))
							Text("Accept")
								.font(.system(size: 14, weight: .semibold))
						}
						.foregroundColor(.white)
						.padding(.vertical, 12)
						.padding(.horizontal, 16)
						.frame(maxWidth: .infinity)
						.background(universalAccentColor)
						.cornerRadius(10)
					}

					Button(action: {
						if let requestId = profileViewModel.pendingFriendRequestId {
							Task {
								await profileViewModel.declineFriendRequest(requestId: requestId)
							}
						}
					}) {
						HStack(spacing: 6) {
							Image(systemName: "xmark")
								.font(.system(size: 14, weight: .semibold))
							Text("Deny")
								.font(.system(size: 14, weight: .semibold))
						}
						.foregroundColor(universalAccentColor)
						.padding(.vertical, 12)
						.padding(.horizontal, 16)
						.frame(maxWidth: .infinity)
						.background(Color.clear)
						.overlay(
							RoundedRectangle(cornerRadius: 10)
								.stroke(universalAccentColor, lineWidth: 1.5)
						)
					}
				}
				.padding(.horizontal, 20)
				.padding(.vertical, 10)
			}

			// Add Friend Button for non-friends or showing Friend Request Sent
			if !isCurrentUserProfile && 
				(profileViewModel.friendshipStatus == .none || profileViewModel.friendshipStatus == .requestSent)
			{
				Button(action: {
					if profileViewModel.friendshipStatus == .none, 
					   let currentUserId = userAuth.spawnUser?.id {
						// Haptic feedback
						let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
						impactGenerator.impactOccurred()
						
						Task {
							await profileViewModel.sendFriendRequest(
								fromUserId: currentUserId,
								toUserId: user.id
							)
						}
					}
				}) {
					HStack {
						if profileViewModel.friendshipStatus == .none {
							Image(systemName: "person.badge.plus")
							Text("Add Friend")
								.bold()
						} else {
							Text("Friend Request Sent")
								.bold()
						}
					}
					.font(.system(size: 16))
					.foregroundColor(.white)
					.padding(.vertical, 10)
					.padding(.horizontal, 20)
					.frame(maxWidth: 200)
					.background(profileViewModel.friendshipStatus == .none ? universalSecondaryColor : Color.gray)
					.cornerRadius(12)
					.scaleEffect(addFriendScale)
					.shadow(
						color: profileViewModel.friendshipStatus == .none ? Color.black.opacity(0.15) : Color.clear,
						radius: addFriendPressed ? 2 : 8,
						x: 0,
						y: addFriendPressed ? 2 : 4
					)
				}
				.buttonStyle(PlainButtonStyle())
				.disabled(profileViewModel.friendshipStatus == .requestSent)
				.padding(.vertical, 10)
				.animation(.easeInOut(duration: 0.15), value: addFriendScale)
				.animation(.easeInOut(duration: 0.15), value: addFriendPressed)
				.onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
					if profileViewModel.friendshipStatus == .none {
						addFriendPressed = pressing
						addFriendScale = pressing ? 0.95 : 1.0
						
						// Additional haptic feedback for press down
						if pressing {
							let selectionGenerator = UISelectionFeedbackGenerator()
							selectionGenerator.selectionChanged()
						}
					}
				}, perform: {})
			}

			// Profile Action Buttons
			profileActionButtonsSection
				.padding(.horizontal, 25)
				.padding(.bottom, 4)

			// Edit Save Cancel buttons (only when editing)
			if isCurrentUserProfile && editingState == .save {
				ProfileEditButtonsView(
					user: user,
					profileViewModel: profileViewModel,
					editingState: $editingState,
					username: $username,
					name: $name,
					selectedImage: $selectedImage,
					whatsappLink: $whatsappLink,
					instagramLink: $instagramLink,
					isImageLoading: $isImageLoading,
					saveProfile: saveProfile
				)
			}

			// Interests Section with Social Media Icons
			ProfileInterestsView(
				user: user,
				profileViewModel: profileViewModel,
				editingState: $editingState,
				newInterest: $newInterest,
				openSocialMediaLink: openSocialMediaLink,
				removeInterest: removeInterest
			)
			.padding(.top, 20)
			.padding(.bottom, 8)

			// User Stats (only for current user or friends)
			userStatsSection

			// Calendar or Activities Section
			if isCurrentUserProfile {
				VStack(spacing: 0) {
					ProfileCalendarView(
						profileViewModel: profileViewModel,
						showCalendarPopup: $showCalendarPopup,
						showActivityDetails: $showActivityDetails,
						navigateToCalendar: $navigateToCalendar,
						navigateToDayActivities: $navigateToDayActivities,
						selectedDayActivities: $selectedDayActivities
					)
					.padding(.horizontal, 16)
					.padding(.bottom, 15)
					
					EmptyView()
				}
			} else {
				// User Activities Section for other users (based on friendship status)
				UserActivitiesSection(
					user: user,
					profileViewModel: profileViewModel,
					showActivityDetails: $showActivityDetails
				)
				.padding(.horizontal, 16)
				.padding(.bottom, 15)
			}
		}
	}

	// Break down body view components into smaller pieces
	private var friendshipBadge: some View {
		Group {
			if !isCurrentUserProfile
				&& profileViewModel.friendshipStatus == .friends
			{
				HStack {
					Image(systemName: "person.crop.circle.badge.checkmark")
					Text("Friends")
				}
				.font(.caption)
				.bold()
				.foregroundColor(figmaGreen)
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
				.background(
					RoundedRectangle(
						cornerRadius: universalRectangleCornerRadius
					)
					.stroke(figmaGreen)
				)
				.cornerRadius(universalRectangleCornerRadius)
				.padding(.bottom, 10)
				.background(universalBackgroundColor)
			}
		}
	}

	private var profileActionButtonsSection: some View {
		Group {
			if isCurrentUserProfile {
				// Original action buttons for current user
				ProfileActionButtonsView(
					user: user as! BaseUserDTO,
					profileViewModel: profileViewModel,
					shareProfile: shareProfile
				)
			} else {
				// Friend action buttons for other users (based on friendship status)
				friendActionButtons
			}
		}
	}

	private var userStatsSection: some View {
		Group {
			if isCurrentUserProfile
				|| profileViewModel.friendshipStatus == .friends
			{
				ProfileStatsView(
					profileViewModel: profileViewModel
				)
			} else {
				EmptyView()
			}
		}
	}

	private var calendarPopupView: some View {
		InfiniteCalendarView(
			activities: profileViewModel.allCalendarActivities,
			isLoading: profileViewModel.isLoadingCalendar,
			userCreationDate: profileViewModel.userProfileInfo?.dateCreated,
			onDismiss: { showCalendarPopup = false },
			onActivitySelected: { activity in
				handleActivitySelection(activity)
			},
			onDayActivitiesSelected: { activities in
				// Close the calendar popup and navigate to day activities
				showCalendarPopup = false
				selectedDayActivities = activities
				navigateToDayActivities = true
			}
		)
	}

	private var calendarFullScreenView: some View {
		ActivityCalendarView(
			profileViewModel: profileViewModel,
			userCreationDate: profileViewModel.userProfileInfo?.dateCreated,
			calendarOwnerName: nil,
			onDismiss: {
				// Reset navigation state when calendar view is dismissed
				navigateToCalendar = false
			},
			onActivitySelected: { activity in
				// Handle single activity - fetch details and show popup directly
				handleActivitySelection(activity)
			},
			onDayActivitiesSelected: { activities in
				// Set the selected activities and navigate to day activities
				selectedDayActivities = activities
				navigateToDayActivities = true
			}
		)
	}
	
	private var dayActivitiesPageView: some View {
		// Get the date from the first activity, or use today as fallback
		let date = selectedDayActivities.first?.dateAsDate ?? Date()
		
		return DayActivitiesPageView(
			date: date,
			activities: selectedDayActivities,
			onDismiss: {
				// Navigate back to calendar view instead of going back to profile
				navigateToDayActivities = false
				navigateToCalendar = true
			},
			onActivitySelected: { activity in
				// Reset navigation state and handle activity selection
				navigateToDayActivities = false
				handleActivitySelection(activity)
			}
		)
	}

	private var activityDetailsView: some View {
		Group {
			if let _ = profileViewModel.selectedActivity {
				EmptyView() // Replaced with global popup system
			}
		}
		.onChange(of: showActivityDetails) { _, isShowing in
			if isShowing, let activity = profileViewModel.selectedActivity {
				let activityColor = getActivityColor(for: activity.id)
				
				// Post notification to show global popup
				NotificationCenter.default.post(
					name: .showGlobalActivityPopup,
					object: nil,
					userInfo: ["activity": activity, "color": activityColor]
				)
				// Reset local state since global popup will handle it
				showActivityDetails = false
				profileViewModel.selectedActivity = nil
			}
		}
	}

	// MARK: - Sub-expressions for better type checking
	
	private var reportUserDrawer: some View {
		ReportUserDrawer(
			user: user,
			onReport: { reportType, description in
				if let currentUser = userAuth.spawnUser {
					Task {
						await profileViewModel.reportUser(
							reporterUserId: currentUser.id,
							reportedUserId: user.id,
							reportType: reportType,
							description: description
						)
						
						// Show success notification
						notificationMessage = "User reported successfully"
						showNotification = true
					}
				}
			}
		)
		.presentationDetents([.medium, .large])
		.presentationDragIndicator(.visible)
	}
	
	private var profileMenuSheet: some View {
		ProfileMenuView(
			user: user,
			showRemoveFriendConfirmation: $showRemoveFriendConfirmation,
			showReportDialog: $showReportDialog,
			showBlockDialog: $showBlockDialog,
			showAddToActivityType: $showAddToActivityType,
			isFriend: profileViewModel.friendshipStatus == .friends,
			copyProfileURL: copyProfileURL,
			shareProfile: shareProfile
		)
		.background(universalBackgroundColor)
		.presentationDetents([.height(profileViewModel.friendshipStatus == .friends ? 364 : 276)])
	}
	
	private var removeFriendConfirmationAlert: some View {
		Group {
			Button("Remove", role: .destructive) {
				if let currentUserId = userAuth.spawnUser?.id {
					Task {
						await profileViewModel.removeFriend(
							currentUserId: currentUserId,
							profileUserId: user.id
						)
						
						// Show success notification
						notificationMessage = "Friend removed successfully"
						showNotification = true
					}
				}
			}
			Button("Cancel", role: .cancel) { }
		}
	}

	private var blockUserAlert: some View {
		Group {
			TextField("Reason for blocking", text: $blockReason)
			Button("Cancel", role: .cancel) {
				blockReason = ""
			}
			Button("Block", role: .destructive) {
				if let currentUserId = userAuth.spawnUser?.id,
					!blockReason.isEmpty
				{
					Task {
						await profileViewModel.blockUser(
							blockerId: currentUserId,
							blockedId: user.id,
							reason: blockReason
						)
						blockReason = ""

						// Navigate back to previous screen after blocking
						presentationMode.wrappedValue.dismiss()
					}
				}
			}
		}
	}

	private var profileMenuOverlay: some View {
		Group {
			if showProfileMenu {
				Color.black.opacity(0.2)
					.ignoresSafeArea()
					.onTapGesture {
						showProfileMenu = false
					}
			}
		}
	}

	private func addInterest() {
		guard !newInterest.isEmpty else { return }

		Task {
			let success = await profileViewModel.addUserInterest(
				userId: user.id,
				interest: newInterest
			)
			await MainActor.run {
				if success {
					newInterest = ""
				}
			}
		}
	}

	private func openSocialMediaLink(platform: String, link: String) {
		// Handle different platforms
		var urlString: String?

		switch platform {
		case "Instagram":
			if link.hasPrefix("@") {
				let username = link.dropFirst()  // Remove the @ symbol
				urlString = "https://instagram.com/\(username)"
			} else {
				urlString = link.hasPrefix("http") ? link : "https://\(link)"
			}
		case "WhatsApp":
			// Format phone number for WhatsApp
			let cleanNumber = link.replacingOccurrences(
				of: "[^0-9]",
				with: "",
				options: .regularExpression
			)
			urlString = "https://wa.me/\(cleanNumber)"
		default:
			urlString = link
		}

		// Open URL if valid
		if let urlString = urlString, let url = URL(string: urlString) {
			UIApplication.shared.open(url)
		}
	}

	private func shareProfile() {
		// Show the custom profile share drawer
		showProfileShareSheet = true
	}

	private func copyProfileURL() {
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

	private func removeInterest(_ interest: String) {
		Task {
			await profileViewModel.removeUserInterest(
				userId: user.id,
				interest: interest
			)
		}
	}

	// Add a function to refresh user data from UserAuthViewModel
	private func refreshUserData() {
		if isCurrentUserProfile, let currentUser = userAuth.spawnUser {
			username = currentUser.username ?? ""
			name = currentUser.name ?? ""
		}
	}

	private func handleActivitySelection(_ activity: CalendarActivityDTO) {
		// First close the calendar popup
		showCalendarPopup = false

		// Then fetch and show the activity details
		Task {
			if let activityId = activity.activityId,
				await profileViewModel.fetchActivityDetails(activityId: activityId)
					!= nil
			{
				await MainActor.run {
					showActivityDetails = true
				}
			}
		}
	}

	// Friend Action Buttons based on friendship status
	private var friendActionButtons: some View {
		Group {
			switch profileViewModel.friendshipStatus {
			case .none:
				// Share Profile button removed for other users
				EmptyView()

			case .requestSent:
				// Request Sent (disabled button)
				HStack {
					Image(systemName: "clock")
					Text("Request Sent")
						.bold()
				}
				.font(.caption)
				.foregroundColor(Color.gray)
				.padding(.vertical, 24)
				.padding(.horizontal, 8)
				.frame(height: 32)
				.frame(maxWidth: .infinity)
				.background(Color.gray.opacity(0.3))
				.cornerRadius(12)

			case .requestReceived:
				// Accept/Deny buttons
				HStack(spacing: 10) {
					Button(action: {
						if let requestId = profileViewModel
							.pendingFriendRequestId
						{
							// Haptic feedback
							let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
							impactGenerator.impactOccurred()
							
							Task {
								await profileViewModel.acceptFriendRequest(
									requestId: requestId
								)
								// Show success drawer after successful acceptance
								showSuccessDrawer = true
							}
						}
					}) {
						HStack(spacing: 4) {
							Image(systemName: "checkmark")
								.font(.system(size: 12, weight: .semibold))
							Text("Accept")
								.font(.system(size: 12, weight: .semibold))
						}
						.foregroundColor(.white)
						.padding(.vertical, 8)
						.padding(.horizontal, 12)
						.frame(height: 32)
						.frame(maxWidth: .infinity)
						.background(universalAccentColor)
						.cornerRadius(8)
						.scaleEffect(acceptButtonScale)
						.shadow(
							color: Color.black.opacity(0.15),
							radius: acceptButtonPressed ? 2 : 8,
							x: 0,
							y: acceptButtonPressed ? 2 : 4
						)
					}
					.buttonStyle(PlainButtonStyle())
					.animation(.easeInOut(duration: 0.15), value: acceptButtonScale)
					.animation(.easeInOut(duration: 0.15), value: acceptButtonPressed)
					.onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
						acceptButtonPressed = pressing
						acceptButtonScale = pressing ? 0.95 : 1.0
						
						// Additional haptic feedback for press down
						if pressing {
							let selectionGenerator = UISelectionFeedbackGenerator()
							selectionGenerator.selectionChanged()
						}
					}, perform: {})

					Button(action: {
						if let requestId = profileViewModel
							.pendingFriendRequestId
						{
							// Haptic feedback
							let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
							impactGenerator.impactOccurred()
							
							Task {
								await profileViewModel.declineFriendRequest(
									requestId: requestId
								)
							}
						}
					}) {
						HStack(spacing: 4) {
							Image(systemName: "xmark")
								.font(.system(size: 12, weight: .semibold))
							Text("Deny")
								.font(.system(size: 12, weight: .semibold))
						}
						.foregroundColor(universalAccentColor)
						.padding(.vertical, 8)
						.padding(.horizontal, 12)
						.frame(height: 32)
						.frame(maxWidth: .infinity)
						.overlay(
							RoundedRectangle(cornerRadius: 8)
								.stroke(universalAccentColor, lineWidth: 1)
						)
						.scaleEffect(denyButtonScale)
						.shadow(
							color: Color.black.opacity(0.15),
							radius: denyButtonPressed ? 2 : 8,
							x: 0,
							y: denyButtonPressed ? 2 : 4
						)
					}
					.buttonStyle(PlainButtonStyle())
					.animation(.easeInOut(duration: 0.15), value: denyButtonScale)
					.animation(.easeInOut(duration: 0.15), value: denyButtonPressed)
					.onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
						denyButtonPressed = pressing
						denyButtonScale = pressing ? 0.95 : 1.0
						
						// Additional haptic feedback for press down
						if pressing {
							let selectionGenerator = UISelectionFeedbackGenerator()
							selectionGenerator.selectionChanged()
						}
					}, perform: {})
				}

			case .friends:
				// Share Profile button removed for other users
				EmptyView()

			default:
				EmptyView()
			}
		}
	}
}

// MARK: - Profile Action Buttons
extension ProfileView {
	private var profileActionButtons: some View {
		HStack(spacing: 12) {
			if isCurrentUserProfile {
				NavigationLink(
					destination: EditProfileView(
						userId: user.id,
						profileViewModel: profileViewModel
					)
				) {
					HStack {
						Image(systemName: "pencil")
						Text("Edit Profile")
							.bold()
					}
					.font(.caption)
					.foregroundColor(universalSecondaryColor)
					.padding(.vertical, 24)
					.padding(.horizontal, 8)
					.frame(height: 32)
					.frame(maxWidth: .infinity)
				}
				.navigationBarBackButtonHidden(true)
				.overlay(
					RoundedRectangle(cornerRadius: 12)
						.stroke(universalSecondaryColor, lineWidth: 1)
				)
			}

			Button(action: {
				shareProfile()
			}) {
				HStack {
					Image(systemName: "square.and.arrow.up")
					Text("Share Profile")
						.bold()
				}
				.font(.caption)
				.foregroundColor(universalSecondaryColor)
				.padding(.vertical, 24)
				.padding(.horizontal, 8)
				.frame(height: 32)
				.frame(maxWidth: .infinity)
				.overlay(
					RoundedRectangle(cornerRadius: 12)
						.stroke(universalSecondaryColor, lineWidth: 1)
				)
			}
		}
	}
}

// MARK: - Profile Edit Buttons
extension ProfileView {
	private var profileEditButtons: some View {
		HStack(spacing: 20) {
			// Cancel Button
			Button(action: {
				// Revert to original values from userAuth.spawnUser
				if let currentUser = userAuth.spawnUser {
					username = currentUser.username ?? ""
					name = currentUser.name ?? ""
					selectedImage = nil

					// Revert social media links
					if let socialMedia = profileViewModel
						.userSocialMedia
					{
						whatsappLink = socialMedia.whatsappLink ?? ""
						instagramLink = socialMedia.instagramLink ?? ""
					}
				}
				
				// Restore original interests
				profileViewModel.restoreOriginalInterests()
				
				editingState = .edit
			}) {
				Text("Cancel")
					.font(.headline)
					.foregroundColor(universalAccentColor)
					.frame(maxWidth: 135)
					.padding()
					.background(
						RoundedRectangle(
							cornerRadius: universalRectangleCornerRadius
						)
						.stroke(universalAccentColor, lineWidth: 1)
					)
			}

			// Save Button
			Button(action: {
				Task {
					await saveProfile()
				}
			}) {
				Text("Save")
					.font(.headline)
					.foregroundColor(.white)
					.frame(maxWidth: 135)
					.padding()
					.background(
						RoundedRectangle(
							cornerRadius: universalRectangleCornerRadius
						)
						.fill(profilePicPlusButtonColor)
					)
			}
			.disabled(isImageLoading)
		}
	}

	private func saveProfile() async {
		// Check if there's a new profile picture
		let hasNewProfilePicture = selectedImage != nil

		// Set loading state immediately if there's an image
		isImageLoading = hasNewProfilePicture

		guard let userId = userAuth.spawnUser?.id else { return }

		// Create a local copy of the selected image before starting async task
		let imageToUpload = selectedImage

		// Update profile info first
		await userAuth.spawnEditProfile(
			username: username,
			name: name
		)

		// Update social media links
		await profileViewModel.updateSocialMedia(
			userId: userId,
			whatsappLink: whatsappLink.isEmpty ? nil : whatsappLink,
			instagramLink: instagramLink.isEmpty ? nil : instagramLink
		)

		// Small delay before processing image update to ensure the text updates are complete
		try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

		// Show notification if there's a profile picture change
		if hasNewProfilePicture {
			await MainActor.run {
				notificationMessage =
					"Sit tight –– your profile pic will update in just a minute..."
				withAnimation {
					showNotification = true
				}
			}
		}

		// Update profile picture if selected
		if let newImage = imageToUpload {
			await userAuth.updateProfilePicture(newImage)

			// Small delay after image upload to ensure the server has processed it
			try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
		}

		if let updatedUser = userAuth.spawnUser {
			username = updatedUser.username ?? ""
			name = updatedUser.name ?? ""
		}

		// Refresh profile data
		await profileViewModel.loadAllProfileData(userId: userId)

		// Update local state with the latest data from the user object
		await MainActor.run {
			// Clear the selected image to force the view to refresh from the server
			selectedImage = nil
			isImageLoading = false
			editingState = .edit
			
			// Invalidate the cached profile picture since we have a new one
			if let userId = userAuth.spawnUser?.id {
				ProfilePictureCache.shared.removeCachedImage(for: userId)
			}
		}
	}
}

// Extension for custom corner rounding
extension View {
	func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
		clipShape(RoundedCorner(radius: radius, corners: corners))
	}
}

@available(iOS 17, *)
#Preview {
	ProfileView(user: BaseUserDTO.danielAgapov)
}

