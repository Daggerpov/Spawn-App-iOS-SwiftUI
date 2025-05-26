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
	@State private var showEventDetails: Bool = false
	@State private var showReportDialog: Bool = false
	@State private var showBlockDialog: Bool = false
	@State private var reportReason: String = ""
	@State private var blockReason: String = ""
	@State private var showRemoveFriendConfirmation: Bool = false
	@State private var showProfileMenu: Bool = false

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
		NavigationStack {
			profileContent
				.background(universalBackgroundColor.ignoresSafeArea())
		}
		.background(universalBackgroundColor)
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
					print("checked friendship status")

					// If they're friends, fetch their events
					if profileViewModel.friendshipStatus == .friends {
						await profileViewModel.fetchProfileEvents(
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
			// Fetch events when friendship status changes to friends
			if newStatus == .friends {
				Task {
					await profileViewModel.fetchProfileEvents(
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
			.sheet(isPresented: $showCalendarPopup) {
				calendarPopupView
			}
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
			.sheet(isPresented: $showEventDetails) {
				eventDetailsView
			}
			.alert("Remove Friend", isPresented: $showRemoveFriendConfirmation)
		{
			removeFriendConfirmationAlert
		}
			.alert("Report User", isPresented: $showReportDialog) {
				reportUserAlert
			}
			.alert("Block User", isPresented: $showBlockDialog) {
				blockUserAlert
			} message: {
				Text(
					"Blocking this user will remove them from your friends list and they won't be able to see your profile or events."
				)
			}
			.sheet(isPresented: $showProfileMenu) {
				ProfileMenuView(
					user: user,
					showRemoveFriendConfirmation: $showRemoveFriendConfirmation,
					showReportDialog: $showReportDialog,
					showBlockDialog: $showBlockDialog,
					isFriend: profileViewModel.friendshipStatus == .friends,
					copyProfileURL: copyProfileURL,
					shareProfile: shareProfile
				)
				.presentationDetents([.height(350)])
			}
			.onTapGesture {
				// Dismiss profile menu if it's showing
				if showProfileMenu {
					showProfileMenu = false
				}
			}
	}

	private var profileWithOverlay: some View {
		ZStack {
			universalBackgroundColor.ignoresSafeArea()
			
			VStack {
				profileInnerComponentsView
					.padding(.horizontal)
			}
			.navigationBarBackButtonHidden()
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					if showBackButton {
						Button(action: {
							presentationMode.wrappedValue.dismiss()
						}) {
							Image(systemName: "chevron.left")
								.foregroundColor(universalAccentColor)
						}
					}
				}

				ToolbarItem(placement: .principal) {
					// Only show the ProfileNameView if it's not the current user's profile
					if !isCurrentUserProfile {
						ProfileNameView(
							user: user,
							refreshFlag: $refreshFlag
						)
					}
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

			// Overlay for profile menu
			profileMenuOverlay
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
					.background(universalAccentColor)
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
			.padding(.bottom, 8)

			// User Stats (only for current user or friends)
			userStatsSection

			// Calendar or Events Section
			calendarOrEventsSection
				.padding(.horizontal, 48)
				.padding(.bottom, 15)
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
					shareProfile: shareProfile
				)
			} else {
				// Friend action buttons for other users (based on friendship status)
				friendActionButtons
			}
		}
	}

	private var calendarOrEventsSection: some View {
		Group {
			if isCurrentUserProfile {
				ProfileCalendarView(
					profileViewModel: profileViewModel,
					showCalendarPopup: $showCalendarPopup,
					showEventDetails: $showEventDetails
				)
			} else {
				// User Events Section for other users (based on friendship status)
				UserEventsSection(
					user: user,
					profileViewModel: profileViewModel,
					showEventDetails: $showEventDetails
				)
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
			onDismiss: { showCalendarPopup = false },
			onEventSelected: { activity in
				handleEventSelection(activity)
			}
		)
	}

	private var eventDetailsView: some View {
		Group {
			if let event = profileViewModel.selectedEvent {
				// Use the same color scheme as EventCardView would
				let eventColor =
					event.isSelfOwned == true
					? universalAccentColor : determineEventColor(for: event)

				EventDescriptionView(
					event: event,
					users: event.participantUsers,
					color: eventColor,
					userId: userAuth.spawnUser?.id ?? UUID()
				)
				.presentationDetents([.medium, .large])
			}
		}
	}

	private var removeFriendConfirmationAlert: some View {
		Group {
			Button("Cancel", role: .cancel) {}
			Button("Remove", role: .destructive) {
				if let currentUserId = userAuth.spawnUser?.id {
					Task {
						await profileViewModel.removeFriend(
							currentUserId: currentUserId,
							profileUserId: user.id
						)
					}
				}
			}
		}
	}

	private var reportUserAlert: some View {
		Group {
			TextField("Reason for report", text: $reportReason)
			Button("Cancel", role: .cancel) {
				reportReason = ""
			}
			Button("Report", role: .destructive) {
				if let currentUserId = userAuth.spawnUser?.id,
					!reportReason.isEmpty
				{
					Task {
						await profileViewModel.reportUser(
							reporterId: currentUserId,
							reportedId: user.id,
							reason: reportReason
						)
						reportReason = ""

						// Show success notification
						notificationMessage = "User reported successfully"
						showNotification = true
					}
				}
			}
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
			await profileViewModel.addUserInterest(
				userId: user.id,
				interest: newInterest
			)
			await MainActor.run {
				newInterest = ""
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

	private func handleEventSelection(_ activity: CalendarActivityDTO) {
		// First close the calendar popup
		showCalendarPopup = false

		// Then fetch and show the event details
		Task {
			if let eventId = activity.eventId,
				await profileViewModel.fetchEventDetails(eventId: eventId)
					!= nil
			{
				await MainActor.run {
					showEventDetails = true
				}
			}
		}
	}

	private func determineEventColor(for event: FullFeedEventDTO) -> Color {
		// Logic to determine event color based on friend tag or category
		return event.category.color()
	}

	// Friend Action Buttons based on friendship status
	private var friendActionButtons: some View {
		Group {
			switch profileViewModel.friendshipStatus {
			case .none:
				// Share Profile button (same as for friends)
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
				HStack(spacing: 12) {
					Button(action: {
						if let requestId = profileViewModel
							.pendingFriendRequestId
						{
							Task {
								await profileViewModel.acceptFriendRequest(
									requestId: requestId
								)
							}
						}
					}) {
						HStack {
							Image(systemName: "checkmark")
							Text("Accept Request")
								.bold()
						}
						.font(.caption)
						.foregroundColor(.white)
						.padding(.vertical, 24)
						.padding(.horizontal, 8)
						.frame(height: 32)
						.frame(maxWidth: .infinity)
						.background(universalAccentColor)
						.cornerRadius(12)
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
						HStack {
							Image(systemName: "xmark")
							Text("Deny")
								.bold()
						}
						.font(.caption)
						.foregroundColor(universalAccentColor)
						.padding(.vertical, 24)
						.padding(.horizontal, 8)
						.frame(height: 32)
						.frame(maxWidth: .infinity)
						.overlay(
							RoundedRectangle(cornerRadius: 12)
								.stroke(universalAccentColor, lineWidth: 1)
						)
					}
				}

			case .friends:
				// Share Profile button (same as in the original view)
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

