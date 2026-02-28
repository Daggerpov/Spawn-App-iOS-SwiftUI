//
//  UserProfileView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created for viewing other users' profiles
//

import PhotosUI
import SwiftUI

/// View for displaying another user's profile
/// Shows friendship status, friend actions, and limited calendar access based on friendship
struct UserProfileView: View {
	let user: Nameable
	@State private var showNotification: Bool = false
	@State private var notificationMessage: String = ""
	@State private var showActivityDetails: Bool = false
	@State private var showReportDialog: Bool = false
	@State private var showBlockDialog: Bool = false
	@State private var blockReason: String = ""
	@State private var showRemoveFriendConfirmation: Bool = false
	@State private var showProfileMenu: Bool = false
	@State private var showAddToActivityType: Bool = false
	@State private var showSuccessDrawer: Bool = false
	@State private var navigateToAddToActivityType: Bool = false

	// Store background refresh task so we can cancel it on disappear
	@State private var backgroundDataLoadTask: Task<Void, Never>?

	// Animation states for 3D effects
	@State private var addFriendPressed = false
	@State private var addFriendScale: CGFloat = 1.0
	@State private var acceptButtonPressed = false
	@State private var acceptButtonScale: CGFloat = 1.0
	@State private var denyButtonPressed = false
	@State private var denyButtonScale: CGFloat = 1.0

	@ObservedObject var userAuth = UserAuthViewModel.shared
	@State var profileViewModel: ProfileViewModel

	// Add environment object for navigation
	@Environment(\.presentationMode) var presentationMode

	init(user: Nameable) {
		self.user = user
		self._profileViewModel = State(
			wrappedValue: ProfileViewModelCache.shared.viewModel(for: user.id)
		)
	}

	/// Preview-only initializer that allows setting a specific friendship status
	init(user: Nameable, previewFriendshipStatus: FriendshipStatus) {
		self.user = user
		let viewModel = ProfileViewModelCache.shared.viewModel(for: user.id)
		viewModel.friendshipStatus = previewFriendshipStatus
		self._profileViewModel = State(wrappedValue: viewModel)
	}

	/// Preview-only initializer that allows setting friendship status and mock activities
	init(user: Nameable, previewFriendshipStatus: FriendshipStatus, previewActivities: [ProfileActivityDTO]) {
		self.user = user
		let viewModel = ProfileViewModelCache.shared.viewModel(for: user.id)
		viewModel.friendshipStatus = previewFriendshipStatus
		viewModel.profileActivities = previewActivities
		self._profileViewModel = State(wrappedValue: viewModel)
	}

	var body: some View {
		ZStack {
			profileContent
				.background(universalBackgroundColor.ignoresSafeArea())
				.background(universalBackgroundColor)

			// Success drawer overlay - placed at root level to cover tab bar
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
		.toolbar(showSuccessDrawer ? .hidden : .visible, for: .tabBar)
		.task {
			// CRITICAL FIX: Load critical profile data on MainActor to block view appearance
			// This prevents empty state flashes and ensures view renders with data

			let currentUserId = userAuth.spawnUser?.id

			// Handle the case where it's the user's own profile
			if let currentUserId = currentUserId, currentUserId == user.id {
				profileViewModel.friendshipStatus = .themself
			}

			// Check if user is a RecommendedFriendUserDTO with relationship status already
			if let recommendedFriend = user as? RecommendedFriendUserDTO,
				recommendedFriend.relationshipStatus != nil
			{
				// Use the relationship status from the DTO - no API call needed
				profileViewModel.setFriendshipStatusFromRecommendedFriend(recommendedFriend)
			}

			// Check if user is a FullFriendUserDTO or MinimalFriendDTO - these are ONLY used for existing friends
			// so we can immediately set the friendship status without an API call
			if user is FullFriendUserDTO || user is MinimalFriendDTO {
				profileViewModel.friendshipStatus = .friends
			}

			// Load critical data that's required for the view to render meaningfully
			// When requestingUserId is provided, profile info will include relationshipStatus
			// (this eliminates the need for a separate checkFriendshipStatus API call)
			await profileViewModel.loadCriticalProfileData(
				userId: user.id,
				requestingUserId: currentUserId
			)

			// Fetch activities if they're friends OR if viewing own profile
			if let currentUserId = currentUserId {
				if profileViewModel.friendshipStatus == .friends || profileViewModel.friendshipStatus == .themself {
					await profileViewModel.fetchProfileActivities(
						profileUserId: user.id
					)
				}
			}

			// Check if task was cancelled before starting background enhancements
			guard !Task.isCancelled else {
				return
			}

			// Capture user properties before Task.detached (they're not Sendable)
			let userId = user.id
			let profilePictureUrl = user.profilePicture

			// Load enhancement data in background (non-blocking progressive enhancements)
			backgroundDataLoadTask = Task.detached(priority: .background) { [profileViewModel] in
				// Profile picture refresh (can use cached version initially)
				if let profilePictureUrl = profilePictureUrl {
					let profilePictureCache = ProfilePictureCache.shared
					_ = await profilePictureCache.getCachedImageWithRefresh(
						for: userId,
						from: profilePictureUrl,
						maxAge: 6 * 60 * 60  // 6 hours
					)
				}

				// Load non-critical enhancement data
				await profileViewModel.loadEnhancementData(userId: userId)
			}
		}
		.onDisappear {
			// Cancel any ongoing background tasks to prevent blocking
			backgroundDataLoadTask?.cancel()
			backgroundDataLoadTask = nil
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
		.accentColor(universalAccentColor)
		.toast(
			isShowing: $showNotification,
			message: notificationMessage,
			duration: 5.0
		)
	}

	// Main content broken into a separate computed property to reduce complexity
	private var profileContent: some View {
		profileWithOverlay
			.modifier(
				UserProfileSheetsModifier(
					showRemoveFriendConfirmation: $showRemoveFriendConfirmation,
					removeFriendConfirmationAlert: AnyView(removeFriendConfirmationAlert),
					showReportDialog: $showReportDialog,
					reportUserDrawer: AnyView(reportUserDrawer),
					showBlockDialog: $showBlockDialog,
					blockUserAlert: AnyView(blockUserAlert),
					showProfileMenu: $showProfileMenu,
					profileMenuSheet: AnyView(profileMenuSheet)
				)
			)
			.onChange(of: showActivityDetails) { _, isShowing in
				if isShowing, let activity = profileViewModel.selectedActivity {
					let activityColor = getActivityColor(for: activity.id)

					NotificationCenter.default.post(
						name: .showGlobalActivityPopup,
						object: nil,
						userInfo: ["activity": activity, "color": activityColor]
					)
					showActivityDetails = false
					profileViewModel.selectedActivity = nil
				}
			}
			.onTapGesture {
				if showProfileMenu {
					showProfileMenu = false
				}
			}
			.background(universalBackgroundColor)
	}

	private var profileWithOverlay: some View {
		ZStack {
			universalBackgroundColor.ignoresSafeArea()

			ScrollView {
				VStack {
					profileInnerComponentsView
						.padding(.horizontal)
				}
			}
			.scrollIndicators(.hidden)
			.navigationBarBackButtonHidden(true)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button(action: {
						presentationMode.wrappedValue.dismiss()
					}) {
						Image(systemName: "chevron.left")
							.font(.system(size: 20, weight: .semibold))
							.foregroundColor(universalAccentColor)
					}
				}

				ToolbarItem(placement: .principal) {
					// Header text removed for other users' profiles
					EmptyView()
				}

				// Menu button for other user profiles
				ToolbarItem(placement: .navigationBarTrailing) {
					Button(action: {
						showProfileMenu = true
					}) {
						Image(systemName: "ellipsis")
							.foregroundColor(universalAccentColor)
					}
				}
			}
			.navigationDestination(isPresented: $showAddToActivityType) {
				AddToActivityTypeView(user: user)
			}
			.navigationDestination(isPresented: $navigateToAddToActivityType) {
				AddToActivityTypeView(user: user)
			}
			.toolbar(showSuccessDrawer ? .hidden : .visible, for: .navigationBar)

			// Overlay for profile menu
			profileMenuOverlay
		}
	}

	private var profileInnerComponentsView: some View {
		VStack(alignment: .center, spacing: 10) {
			// Profile Header (Profile Picture + Name) - read-only for other users
			VStack(spacing: 16) {
				// Profile Picture
				ZStack(alignment: .bottomTrailing) {
					if let pfpUrl = user.profilePicture {
						if MockAPIService.isMocking {
							Image(pfpUrl)
								.ProfileImageModifier(imageType: .profilePage)
						} else {
							CachedProfileImage(
								userId: user.id,
								url: URL(string: pfpUrl),
								imageType: .profilePage
							)
						}
					} else {
						Circle()
							.fill(Color.gray)
							.frame(width: 128, height: 128)
					}
				}

				// Name and Username
				ProfileNameView(
					user: user,
					refreshFlag: .constant(false)
				)
			}

			// Friendship badge (for other users' profiles)
			friendshipBadge

			// Friend Request Buttons (for incoming requests)
			if profileViewModel.friendshipStatus == .requestReceived {
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
			if profileViewModel.friendshipStatus == .none || profileViewModel.friendshipStatus == .requestSent {
				Button(action: {
					if profileViewModel.friendshipStatus == .none,
						let currentUserId = userAuth.spawnUser?.id
					{
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
					HStack(spacing: 12) {
						if profileViewModel.friendshipStatus == .none {
							Image(systemName: "person.badge.plus")
								.foregroundColor(.white)
							Text("Add Friend")
								.bold()
								.foregroundColor(.white)
						} else {
							Image(systemName: "person.badge.clock")
								.foregroundColor(universalAccentColor)
							Text("Request Sent")
								.bold()
								.foregroundColor(universalAccentColor)
						}
					}
					.font(.onestMedium(size: 16))
					.padding(
						EdgeInsets(
							top: 10, leading: 20, bottom: 10, trailing: 20
						)
					)
					.frame(maxWidth: 200)
					.background(
						profileViewModel.friendshipStatus == .none
							? universalSecondaryColor
							: Color.clear
					)
					.cornerRadius(12)
					.overlay(
						RoundedRectangle(cornerRadius: 12)
							.stroke(
								profileViewModel.friendshipStatus == .requestSent
									? universalAccentColor
									: Color.clear,
								lineWidth: 2
							)
					)
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
				.animation(.easeInOut(duration: 0.2), value: profileViewModel.friendshipStatus)
				.onLongPressGesture(
					minimumDuration: 0, maximumDistance: .infinity,
					pressing: { pressing in
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

			// Friend action buttons for other users (based on friendship status)
			friendActionButtons
				.padding(.horizontal, 25)
				.padding(.bottom, 4)

			// Interests Section with Social Media Icons (read-only for other users)
			ProfileInterestsView(
				user: user,
				profileViewModel: profileViewModel,
				editingState: .constant(.edit),
				newInterest: .constant(""),
				openSocialMediaLink: openSocialMediaLink,
				removeInterest: { _ in }  // No-op for other users
			)
			.padding(.top, 20)
			.padding(.bottom, 8)

			// User Activities Section for other users (based on friendship status)
			UserActivitiesSection(
				user: user,
				profileViewModel: profileViewModel,
				showActivityDetails: $showActivityDetails
			)
			.padding(.bottom, 100)
		}
	}

	// Break down body view components into smaller pieces
	private var friendshipBadge: some View {
		Group {
			if profileViewModel.friendshipStatus == .friends {
				HStack {
					Image(systemName: "person.crop.circle.badge.checkmark")
					Text("Friends")
				}
				.font(.onestMedium(size: 16))
				.foregroundColor(Color(hex: colorsGray900))
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
				.background(
					RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
						.fill(Color(hex: colorsGreen500))
				)
				.padding(.bottom, 10)
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
			Button("Cancel", role: .cancel) {}
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
		// Post notification to show global profile share drawer
		NotificationCenter.default.post(
			name: .showGlobalProfileShareDrawer,
			object: nil,
			userInfo: ["user": user]
		)
	}

	private func copyProfileURL() {
		ServiceConstants.generateProfileShareCodeURL(for: user.id) { profileURL in
			let url = profileURL ?? ServiceConstants.generateProfileShareURL(for: user.id)

			// Clear the pasteboard first to avoid any contamination
			UIPasteboard.general.items = []

			// Set only the URL string to the pasteboard
			UIPasteboard.general.string = url.absoluteString

			// Show notification toast
			Task { @MainActor in
				InAppNotificationManager.shared.showNotification(
					title: "Link copied to clipboard",
					message: "Profile link has been copied to your clipboard",
					type: .success,
					duration: 5.0
				)
			}
		}
	}

	// Friend Action Buttons based on friendship status
	private var friendActionButtons: some View {
		Group {
			switch profileViewModel.friendshipStatus {
			case .none, .requestSent:
				// Share Profile button removed for other users
				EmptyView()

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
					.onLongPressGesture(
						minimumDuration: 0, maximumDistance: .infinity,
						pressing: { pressing in
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
					.onLongPressGesture(
						minimumDuration: 0, maximumDistance: .infinity,
						pressing: { pressing in
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

// MARK: - UserProfile Sheets Modifier
struct UserProfileSheetsModifier: ViewModifier {
	@Binding var showRemoveFriendConfirmation: Bool
	var removeFriendConfirmationAlert: AnyView
	@Binding var showReportDialog: Bool
	var reportUserDrawer: AnyView
	@Binding var showBlockDialog: Bool
	var blockUserAlert: AnyView
	@Binding var showProfileMenu: Bool
	var profileMenuSheet: AnyView

	func body(content: Content) -> some View {
		content
			.confirmationDialog(
				"Remove this friend?",
				isPresented: $showRemoveFriendConfirmation,
				titleVisibility: .visible
			) {
				removeFriendConfirmationAlert
			}
			.sheet(isPresented: $showReportDialog) {
				reportUserDrawer
			}
			.alert("Block User", isPresented: $showBlockDialog) {
				blockUserAlert
			}
			.sheet(isPresented: $showProfileMenu) {
				profileMenuSheet
			}
	}
}

@available(iOS 17, *)
#Preview("Friends with Activities") {
	UserProfileView(
		user: BaseUserDTO.danielAgapov,
		previewFriendshipStatus: .friends,
		previewActivities: ProfileActivityDTO.mockActivities
	)
}

@available(iOS 17, *)
#Preview("Friends (No Activities)") {
	UserProfileView(user: BaseUserDTO.danielAgapov, previewFriendshipStatus: .friends)
}

@available(iOS 17, *)
#Preview("Not Friends") {
	UserProfileView(user: BaseUserDTO.danielAgapov)
}
