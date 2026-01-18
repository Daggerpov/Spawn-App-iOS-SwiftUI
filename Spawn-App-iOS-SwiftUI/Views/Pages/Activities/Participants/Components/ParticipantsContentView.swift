import SwiftUI

// MARK: - Embedded Participants Content View (for use within drawers)
struct ParticipantsContentView: View {
	@ObservedObject var activity: FullFeedActivityDTO
	var backgroundColor: Color
	var isExpanded: Bool
	let onBack: () -> Void

	// Optional binding to control tab selection for current user navigation
	@Binding var selectedTab: TabType?

	// Callback to dismiss the drawer
	let onDismiss: () -> Void

	// State for other user profile navigation
	@State private var showProfile = false
	@State private var selectedUser: BaseUserDTO?

	// Check if a user is the current user
	private func isCurrentUser(_ user: BaseUserDTO) -> Bool {
		guard let currentUser = UserAuthViewModel.shared.spawnUser else { return false }
		return currentUser.id == user.id
	}

	// Navigation logic
	private func navigateToUserProfile(_ user: BaseUserDTO) {
		if isCurrentUser(user) && selectedTab != nil {
			// Navigate to profile tab for current user
			selectedTab = .profile
		} else {
			// Show full screen cover for other users
			selectedUser = user
			showProfile = true
		}
		// Dismiss the drawer when navigating to profiles
		onDismiss()
	}

	init(
		activity: FullFeedActivityDTO, backgroundColor: Color, isExpanded: Bool, onBack: @escaping () -> Void,
		selectedTab: Binding<TabType?> = .constant(nil), onDismiss: @escaping () -> Void = {}
	) {
		self.activity = activity
		self.backgroundColor = backgroundColor
		self.isExpanded = isExpanded
		self.onBack = onBack
		self._selectedTab = selectedTab
		self.onDismiss = onDismiss
	}

	var body: some View {
		Group {
			if isExpanded {
				// When expanded, use GeometryReader for safe area handling
				GeometryReader { geometry in
					VStack(spacing: 0) {
						ParticipantsHeaderView(onBack: onBack)
							.padding(.top, geometry.safeAreaInsets.top + 24)

						// Participants content that takes remaining space
						ScrollView {
							SharedParticipantsContent(activity: activity) { user in
								navigateToUserProfile(user)
							}
							.padding(.horizontal, 24)
							.padding(.bottom, 20)
						}
					}
				}
			} else {
				// When minimized, don't use GeometryReader to avoid expanding to fill available space
				VStack(spacing: 0) {
					ParticipantsHeaderView(onBack: onBack)

					// Participants content with fixed height when minimized
					ScrollView {
						SharedParticipantsContent(activity: activity) { user in
							navigateToUserProfile(user)
						}
						.padding(.horizontal, 24)
						.padding(.bottom, 85)
					}
					.frame(maxHeight: 500)  // Limit height when minimized to match main content
				}
			}
		}
		.fullScreenCover(isPresented: $showProfile) {
			if let selectedUser = selectedUser {
				UserProfileView(user: selectedUser)
			}
		}
	}
}
