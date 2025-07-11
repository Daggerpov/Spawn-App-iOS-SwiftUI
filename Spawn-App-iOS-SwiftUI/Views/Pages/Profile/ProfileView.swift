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

	@StateObject var userAuth = UserAuthViewModel.shared
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
		self.username = user.username
		self.name = user.name ?? ""
	}

	var body: some View {
		profileContent
			.background(universalBackgroundColor.ignoresSafeArea())
			.background(universalBackgroundColor)
		.onChange(of: editingState) { newState in
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

			// Load profile data
			Task {
				await profileViewModel.loadAllProfileData(userId: user.id)

				// Initialize social media links
				if let socialMedia = profileViewModel.userSocialMedia {
					await MainActor.run {
						whatsappLink = socialMedia.whatsappLink ?? ""
						instagramLink = socialMedia.instagramLink ?? ""
					}
				}

				// Check friendship status if not viewing own profile
				if !isCurrentUserProfile,
					let currentUserId = userAuth.spawnUser?.id
				{
					await profileViewModel.checkFriendshipStatus(
						currentUserId: currentUserId,
						profileUserId: user.id
					)

					// If they're friends, fetch their activities
					if profileViewModel.friendshipStatus == .friends {
						await profileViewModel.fetchProfileActivities(
							profileUserId: user.id
						)
					}
				}

				// Determine if back button should be shown based on navigation
				if !isCurrentUserProfile {
					showBackButton = true
				}
			}
		}
		.onChange(of: userAuth.spawnUser) { newUser in
			// Update local state whenever spawnUser changes
			refreshUserData()
		}
		.onChange(of: profileViewModel.userSocialMedia) { newSocialMedia in
			// Update local state when social media changes
			if let socialMedia = newSocialMedia {
				whatsappLink = socialMedia.whatsappLink ?? ""
				instagramLink = socialMedia.instagramLink ?? ""
			}
		}
		.onChange(of: profileViewModel.friendshipStatus) { newStatus in
			// Fetch activities when friendship status changes to friends
			if newStatus == .friends {
				Task {
					await profileViewModel.fetchProfileActivities(
						profileUserId: user.id
					)
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
			duration: 3.0
		)
	}

	// Main content broken into a separate computed property to reduce complexity
	private var profileContent: some View {
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
			.background(
				NavigationLink(
					destination: AddToActivityTypeView(user: user),
					isActive: $showAddToActivityType
				) {
					EmptyView()
				}
				.hidden()
			)
			.background(
				NavigationLink(
					destination: AddToActivityTypeView(user: user),
					isActive: $navigateToAddToActivityType
				) {
					EmptyView()
				}
				.hidden()
			)

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
				}
				.disabled(profileViewModel.friendshipStatus == .requestSent)
				.padding(.vertical, 10)
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
					
					// Hidden NavigationLink for calendar
					NavigationLink(
						destination: calendarFullScreenView,
						isActive: $navigateToCalendar
					) {
						EmptyView()
					}
					.hidden()
					
					// Hidden NavigationLink for day activities
					NavigationLink(
						destination: dayActivitiesPageView,
						isActive: $navigateToDayActivities
					) {
						EmptyView()
					}
					.hidden()
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
					user: user,
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
			}
		)
	}
	
	private var dayActivitiesPageView: some View {
		DayActivitiesPageView(
			date: selectedDayActivities.first?.date ?? Date(),
			activities: selectedDayActivities,
			onDismiss: {
				// Reset navigation state when day activities view is dismissed
				navigateToDayActivities = false
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
			if let activity = profileViewModel.selectedActivity {
				// Use the same color scheme as ActivityCardView would
				let activityColor =
					activity.isSelfOwned == true
					? universalAccentColor : getActivityColor(for: activity.id)

				ActivityDescriptionView(
					activity: activity,
					users: activity.participantUsers,
					color: activityColor,
					userId: userAuth.spawnUser?.id ?? UUID()
				)
				.presentationDetents([.medium, .large])
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
		// Create a URL to share (could be a deep link to the user's profile)
		let profileURL = "https://spawnapp.com/profile/\(user.id)"
		let shareText =
			"Check out \(FormatterService.shared.formatName(user: user))'s profile on Spawn!"

		let activityItems: [Any] = [shareText, profileURL]
		let activityController = UIActivityViewController(
			activityItems: activityItems,
			applicationActivities: nil
		)

		// Present the activity controller
		if let windowScene = UIApplication.shared.connectedScenes.first
			as? UIWindowScene,
			let rootViewController = windowScene.windows.first?
				.rootViewController
		{
			rootViewController.present(
				activityController,
				animated: true,
				completion: nil
			)
		}
	}

	private func copyProfileURL() {
		let profileURL = "https://spawnapp.com/profile/\(user.id)"
		UIPasteboard.general.string = profileURL

		// Show notification toast
		notificationMessage = "Profile URL copied to clipboard"
		showNotification = true
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
			username = currentUser.username
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
					}

					Button(action: {
						if let requestId = profileViewModel
							.pendingFriendRequestId
						{
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
					}
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
					username = currentUser.username
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
			username = updatedUser.username
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

struct RoundedCorner: Shape {
	var radius: CGFloat = .infinity
	var corners: UIRectCorner = .allCorners

	func path(in rect: CGRect) -> Path {
		let path = UIBezierPath(
			roundedRect: rect,
			byRoundingCorners: corners,
			cornerRadii: CGSize(width: radius, height: radius)
		)
		return Path(path.cgPath)
	}
}

@available(iOS 17, *)
#Preview {
	ProfileView(user: BaseUserDTO.danielAgapov)
}

// MARK: - View Modifiers for better organization

struct ImagePickerModifier: ViewModifier {
	@Binding var showImagePicker: Bool
	@Binding var selectedImage: UIImage?
	@Binding var isImageLoading: Bool
	
	func body(content: Content) -> some View {
		content
			.sheet(isPresented: $showImagePicker) {
				if selectedImage != nil {
					isImageLoading = true
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
						isImageLoading = false
					}
				}
			} content: {
				SwiftUIImagePicker(selectedImage: $selectedImage)
					.ignoresSafeArea()
			}
			.onChange(of: selectedImage) { newImage in
				if newImage != nil {
					// Force UI update when image changes
					DispatchQueue.main.async {
						isImageLoading = true
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
							isImageLoading = false
						}
					}
				}
			}
	}
}

struct SheetsAndAlertsModifier: ViewModifier {
	@Binding var showActivityDetails: Bool
	let activityDetailsView: AnyView
	@Binding var showRemoveFriendConfirmation: Bool
	let removeFriendConfirmationAlert: AnyView
	@Binding var showReportDialog: Bool
	let reportUserDrawer: AnyView
	@Binding var showBlockDialog: Bool
	let blockUserAlert: AnyView
	@Binding var showProfileMenu: Bool
	let profileMenuSheet: AnyView
	
	func body(content: Content) -> some View {
		content
			.sheet(isPresented: $showActivityDetails) {
				activityDetailsView
			}
			.alert("Remove Friend", isPresented: $showRemoveFriendConfirmation) {
				removeFriendConfirmationAlert
			}
			.sheet(isPresented: $showReportDialog) {
				reportUserDrawer
			}
			.alert("Block User", isPresented: $showBlockDialog) {
				blockUserAlert
			} message: {
				Text("Blocking this user will remove them from your friends list and they won't be able to see your profile or activities.")
			}
			.sheet(isPresented: $showProfileMenu) {
				profileMenuSheet
			}
	}
}

