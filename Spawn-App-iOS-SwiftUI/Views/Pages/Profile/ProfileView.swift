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
	@State private var showReportDialog: Bool = false
	@State private var showBlockDialog: Bool = false
	@State private var reportReason: String = ""
	@State private var blockReason: String = ""
	@State private var showRemoveFriendConfirmation: Bool = false
	@State private var showProfileMenu: Bool = false
	@State private var showAddToActivityType: Bool = false

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
		NavigationView {
			profileContent
				.background(universalBackgroundColor.ignoresSafeArea())
			.background(universalBackgroundColor)
		}
		.navigationViewStyle(StackNavigationViewStyle())
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
			.sheet(isPresented: $showActivityDetails) {
				activityDetailsView
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
					"Blocking this user will remove them from your friends list and they won't be able to see your profile or activities."
				)
			}
			.sheet(isPresented: $showProfileMenu) {
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
				.presentationDetents([.height(profileViewModel.friendshipStatus == .friends ? 410 : 320)])
			}
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

			// Overlay for profile menu
			profileMenuOverlay
		}
	}

	private var profileInnerComponentsView: some View {
		ScrollView {
			VStack(alignment: .center, spacing: 0) {
				// Profile Header (Profile Picture + Name)
				VStack(spacing: 16) {
					// Profile Picture
					ZStack {
						Circle()
							.fill(Color.gray.opacity(0.3))
							.frame(width: 128, height: 128)
						
						if let selectedImage = selectedImage {
							Image(uiImage: selectedImage)
								.resizable()
								.aspectRatio(contentMode: .fill)
								.frame(width: 128, height: 128)
								.clipShape(Circle())
						} else {
							// Default profile image or placeholder
							Circle()
								.fill(LinearGradient(
									gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								))
								.frame(width: 128, height: 128)
						}
						
						// Edit button overlay for current user
						if isCurrentUserProfile && editingState == .save {
							Button(action: {
								showImagePicker = true
							}) {
								Image(systemName: "camera.fill")
									.font(.system(size: 16))
									.foregroundColor(.white)
									.frame(width: 32, height: 32)
									.background(universalAccentColor)
									.clipShape(Circle())
							}
							.offset(x: 45, y: 45)
						}
					}
					
					// Name and username
					VStack(spacing: 4) {
						if editingState == .save && isCurrentUserProfile {
							TextField("Full Name", text: $name)
								.font(.onestBold(size: 24))
								.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
								.multilineTextAlignment(.center)
								.textFieldStyle(RoundedBorderTextFieldStyle())
								.frame(maxWidth: 200)
						} else {
							Text(name.isEmpty ? user.name ?? "Unknown" : name)
								.font(.onestBold(size: 24))
								.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
						}
						
						if editingState == .save && isCurrentUserProfile {
							TextField("Username", text: $username)
								.font(.onestRegular(size: 16))
								.foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
								.multilineTextAlignment(.center)
								.textFieldStyle(RoundedBorderTextFieldStyle())
								.frame(maxWidth: 200)
						} else {
							Text("@\(username)")
								.font(.onestRegular(size: 16))
								.foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
						}
					}
					
					// Action buttons (Edit Profile / Share Profile)
					if isCurrentUserProfile {
						HStack(spacing: 8) {
							Button(action: {
								if editingState == .edit {
									editingState = .save
								} else {
									Task{
										await saveProfile()
									}
								}
							}) {
								HStack(spacing: 8) {
									Image(systemName: editingState == .edit ? "pencil" : "checkmark")
										.font(.system(size: 12, weight: .bold))
										.foregroundColor(universalAccentColor)
									Text(editingState == .edit ? "Edit Profile" : "Save")
										.font(.onestSemiBold(size: 12))
										.foregroundColor(universalAccentColor)
								}
								.padding(.horizontal, 16)
								.padding(.vertical, 8)
								.background(.white)
								.cornerRadius(12)
								.overlay(
									RoundedRectangle(cornerRadius: 12)
										.stroke(universalAccentColor, lineWidth: 0.5)
								)
							}
							.frame(width: 128)
							
							Button(action: shareProfile) {
								HStack(spacing: 8) {
									Image(systemName: "square.and.arrow.up")
										.font(.system(size: 12, weight: .bold))
										.foregroundColor(universalAccentColor)
									Text("Share Profile")
										.font(.onestSemiBold(size: 12))
										.foregroundColor(universalAccentColor)
								}
								.padding(.horizontal, 16)
								.padding(.vertical, 8)
								.background(.white)
								.cornerRadius(12)
								.overlay(
									RoundedRectangle(cornerRadius: 12)
										.stroke(universalAccentColor, lineWidth: 0.5)
								)
							}
							.frame(width: 128)
						}
					}
				}
				.padding(.top, 20)
				
				// Friendship badge and buttons for other users
				friendshipBadge
				
				// Friend Request Buttons (for incoming requests)
				if !isCurrentUserProfile && profileViewModel.friendshipStatus == .requestReceived {
					HStack(spacing: 12) {
						Button(action: {
							if let requestId = profileViewModel.pendingFriendRequestId {
								Task {
									await profileViewModel.acceptFriendRequest(requestId: requestId)
								}
							}
						}) {
							HStack {
								Image(systemName: "checkmark")
								Text("Accept Request")
									.bold()
							}
							.font(.system(size: 16))
							.foregroundColor(.white)
							.padding(.vertical, 10)
							.padding(.horizontal, 20)
							.frame(maxWidth: .infinity)
							.background(universalAccentColor)
							.cornerRadius(12)
						}

						Button(action: {
							if let requestId = profileViewModel.pendingFriendRequestId {
								Task {
									await profileViewModel.declineFriendRequest(requestId: requestId)
								}
							}
						}) {
							HStack {
								Image(systemName: "xmark")
								Text("Deny")
									.bold()
							}
							.font(.system(size: 16))
							.foregroundColor(universalAccentColor)
							.padding(.vertical, 10)
							.padding(.horizontal, 20)
							.frame(maxWidth: .infinity)
							.background(Color.clear)
							.overlay(
								RoundedRectangle(cornerRadius: 12)
									.stroke(universalAccentColor, lineWidth: 2)
							)
						}
					}
					.padding(.horizontal, 20)
					.padding(.vertical, 10)
				}

				// Add Friend Button for non-friends
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
				
				// Stats Section
				HStack(spacing: 48) {
					VStack(spacing: 8) {
						HStack(spacing: 4) {
							Image(systemName: "link")
								.font(.system(size: 20))
								.foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
							Text("49")
								.font(.system(size: 20))
								.foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
						}
						Text("People\nmet")
							.font(.onestRegular(size: 12))
							.foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
							.multilineTextAlignment(.center)
					}
					
					VStack(spacing: 8) {
						HStack(spacing: 4) {
							Image(systemName: "star")
								.font(.system(size: 20))
								.foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
							Text("4")
								.font(.system(size: 20))
								.foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
						}
						Text("Spawns\nmade")
							.font(.onestRegular(size: 12))
							.foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
							.multilineTextAlignment(.center)
					}
					
					VStack(spacing: 8) {
						HStack(spacing: 4) {
							Image(systemName: "calendar")
								.font(.system(size: 20))
								.foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
							Text("16")
								.font(.system(size: 20))
								.foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
						}
						Text("Spawns\njoined")
							.font(.onestRegular(size: 12))
							.foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
							.multilineTextAlignment(.center)
					}
				}
				.padding(.vertical, 24)
				
				// Interests Section
				VStack(spacing: 0) {
					// Interests Header with Social Media Icons
					HStack {
						// Interests header badge
						HStack {
							Text("Interests + Hobbies")
								.font(.onestBold(size: 14))
								.foregroundColor(.white)
								.padding(.vertical, 8)
								.padding(.horizontal, 12)
								.background(Color(red: 1, green: 0.45, blue: 0.44))
								.cornerRadius(12)
						}
						
						Spacer()
						
						// Social media icons
						if !profileViewModel.isLoadingSocialMedia {
							HStack(spacing: 10) {
								if let whatsappLink = profileViewModel.userSocialMedia?.whatsappLink, !whatsappLink.isEmpty {
									Image("whatsapp")
										.resizable()
										.scaledToFit()
										.frame(width: 36, height: 36)
										.rotationEffect(.degrees(-8))
										.shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 1)
										.onTapGesture {
											openSocialMediaLink(
												platform: "WhatsApp",
												link: whatsappLink
											)
										}
								}

								if let instagramLink = profileViewModel.userSocialMedia?.instagramLink, !instagramLink.isEmpty {
									Image("instagram")
										.resizable()
										.scaledToFit()
										.frame(width: 36, height: 36)
										.rotationEffect(.degrees(8))
										.shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 1)
										.onTapGesture {
											openSocialMediaLink(
												platform: "Instagram",
												link: instagramLink
											)
										}
								}
							}
						}
					}
					.padding(.horizontal, 16)
					.padding(.bottom, 8)
					
					// Interests Container
					if profileViewModel.isLoadingInterests {
						ProgressView()
							.frame(maxWidth: .infinity, alignment: .center)
							.padding()
					} else if profileViewModel.userInterests.isEmpty {
						RoundedRectangle(cornerRadius: 12)
							.stroke(Color(red: 1, green: 0.45, blue: 0.44), lineWidth: 0.5)
							.frame(height: 100)
							.overlay(
								Text("No interests added yet")
									.font(.onestRegular(size: 14))
									.foregroundColor(.gray)
							)
							.padding(.horizontal, 16)
					} else {
						// Interests Tags
						InterestsTagsView(interests: profileViewModel.userInterests)
							.padding(.horizontal, 16)
					}
				}
				
				// Edit Save Cancel buttons (only when editing)
				if isCurrentUserProfile && editingState == .save {
					HStack(spacing: 16) {
						Button(action: {
							editingState = .edit
							// Reset to original values
							refreshUserData()
						}) {
							Text("Cancel")
								.font(.onestSemiBold(size: 14))
								.foregroundColor(.red)
								.padding(.vertical, 10)
								.padding(.horizontal, 24)
								.background(Color.clear)
								.overlay(
									RoundedRectangle(cornerRadius: 12)
										.stroke(Color.red, lineWidth: 1)
								)
						}
						
						Button(action: {
							Task {
								await saveProfile()
							}
						}) {
							Text("Save Changes")
								.font(.onestSemiBold(size: 14))
								.foregroundColor(.white)
								.padding(.vertical, 10)
								.padding(.horizontal, 24)
								.background(universalAccentColor)
								.cornerRadius(12)
						}
					}
					.padding(.top, 16)
				}
				
				// Calendar/Activity Grid Section
				VStack(spacing: 16) {
					// Calendar weekday headers
					HStack(spacing: 4.57) {
						ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
							Text(day)
								.font(.onestMedium(size: 9.14))
								.foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
								.frame(maxWidth: .infinity)
						}
					}
					.padding(.horizontal, 16)
					
					// Activity Calendar Grid
					ActivityCalendarGrid()
						.padding(.horizontal, 16)
				}
				.padding(.top, 24)
			}
			.padding(.bottom, 100) // Add bottom padding for tab bar
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
		InfiniteCalendarView(
			activities: profileViewModel.allCalendarActivities,
			isLoading: profileViewModel.isLoadingCalendar,
			userCreationDate: profileViewModel.userProfileInfo?.dateCreated,
			onDismiss: { navigateToCalendar = false },
			onActivitySelected: { activity in
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

