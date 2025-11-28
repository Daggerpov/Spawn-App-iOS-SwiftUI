//
//  MyProfileView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created for separating own profile from other users' profiles
//

import PhotosUI
import SwiftUI

/// View for displaying the current user's own profile
/// Shows editable fields, settings access, and personal calendar
struct MyProfileView: View {
	let user: BaseUserDTO
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
	@State private var showCalendarPopup: Bool = false
	@State private var navigateToCalendar: Bool = false
	@State private var showActivityDetails: Bool = false
	@State private var navigateToDayActivities: Bool = false
	@State private var selectedDayActivities: [CalendarActivityDTO] = []
	@State private var showProfileShareSheet: Bool = false

	// Store background refresh task so we can cancel it on disappear
	@State private var backgroundDataLoadTask: Task<Void, Never>?

	@ObservedObject var userAuth = UserAuthViewModel.shared
	@StateObject var profileViewModel = ProfileViewModel()

	// Add environment object for navigation
	@Environment(\.presentationMode) var presentationMode

	init(user: BaseUserDTO) {
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
				// CRITICAL FIX: Load critical profile data on MainActor to block view appearance
				// This prevents empty state flashes and ensures view renders with data

				// Load critical data that's required for the view to render meaningfully
				await profileViewModel.loadCriticalProfileData(userId: user.id)

				// Initialize social media links from loaded data
				if let socialMedia = profileViewModel.userSocialMedia {
					whatsappLink = socialMedia.whatsappLink ?? ""
					instagramLink = socialMedia.instagramLink ?? ""
				}

				// Check if task was cancelled before starting background enhancements
				guard !Task.isCancelled else {
					return
				}

				// Load enhancement data in background (non-blocking progressive enhancements)
				backgroundDataLoadTask = Task.detached(priority: .background) {
					// Profile picture refresh (can use cached version initially)
					if let profilePictureUrl = await user.profilePicture {
						let profilePictureCache = ProfilePictureCache.shared
						_ = await profilePictureCache.getCachedImageWithRefresh(
							for: await user.id,
							from: profilePictureUrl,
							maxAge: 6 * 60 * 60  // 6 hours
						)
					}

					// Load non-critical enhancement data
					await profileViewModel.loadEnhancementData(userId: await user.id)
				}
			}
			.onDisappear {
				// Cancel any ongoing background tasks to prevent blocking
				backgroundDataLoadTask?.cancel()
				backgroundDataLoadTask = nil
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
			.onChange(of: navigateToDayActivities) { _, newValue in
				if newValue {
					// Ensure navigation happens on main thread
					DispatchQueue.main.async {
						// Navigation logic handled by the view
					}
				}
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
				.modifier(
					ImagePickerModifier(
						showImagePicker: $showImagePicker,
						selectedImage: $selectedImage,
						isImageLoading: $isImageLoading
					)
				)
				.modifier(
					MyProfileSheetsModifier(
						showActivityDetails: $showActivityDetails,
						activityDetailsView: AnyView(activityDetailsView)
					)
				)
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
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .principal) {
					// Header text removed for cleaner look
					EmptyView()
				}

				// Settings button for current user profile
				ToolbarItem(placement: .navigationBarTrailing) {
					NavigationLink(destination: SettingsView()) {
						Image(systemName: "gearshape")
							.foregroundColor(universalAccentColor)
					}
				}
			}
			.navigationDestination(isPresented: $navigateToCalendar) {
				calendarFullScreenView
			}
			.navigationDestination(isPresented: $navigateToDayActivities) {
				dayActivitiesPageView
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
				editingState: $editingState
			)

			// Profile Action Buttons
			ProfileActionButtonsView(
				user: user,
				profileViewModel: profileViewModel,
				shareProfile: shareProfile
			)
			.padding(.horizontal, 25)
			.padding(.bottom, 4)

			// Edit Save Cancel buttons (only when editing)
			if editingState == .save {
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

			// User Stats
			ProfileStatsView(
				profileViewModel: profileViewModel
			)

			// Calendar Section
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
		}
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
			if profileViewModel.selectedActivity != nil {
				EmptyView()  // Replaced with global popup system
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

	private func shareProfile() {
		// Show the custom profile share drawer
		showProfileShareSheet = true
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
		if let currentUser = userAuth.spawnUser {
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

		// Invalidate the cached profile picture since we have a new one
		if let userId = userAuth.spawnUser?.id {
			await ProfilePictureCache.shared.removeCachedImage(for: userId)
		}

		// Update local state with the latest data from the user object
		await MainActor.run {
			// Clear the selected image to force the view to refresh from the server
			selectedImage = nil
			isImageLoading = false
			editingState = .edit
		}
	}
}

// MARK: - MyProfile Sheets Modifier
struct MyProfileSheetsModifier: ViewModifier {
	@Binding var showActivityDetails: Bool
	var activityDetailsView: AnyView

	func body(content: Content) -> some View {
		content
			.sheet(isPresented: $showActivityDetails) {
				activityDetailsView
			}
	}
}

@available(iOS 17, *)
#Preview {
	MyProfileView(user: BaseUserDTO.danielAgapov)
}
