//
//  ProfilePictureView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/20/25.
//
import SwiftUI

struct ProfilePictureView: View {
	let user: BaseUserDTO
	let width: CGFloat = 48
	let height: CGFloat = 48
	let allowsNavigation: Bool
	@State var showProfile = false

	// Optional binding to control tab selection for current user navigation
	@Binding var selectedTab: TabType?

	// Check if this is the current user
	private var isCurrentUser: Bool {
		guard let currentUser = UserAuthViewModel.shared.spawnUser else { return false }
		return currentUser.id == user.id
	}

	init(user: BaseUserDTO, selectedTab: Binding<TabType?> = .constant(nil), allowsNavigation: Bool = true) {
		self.user = user
		self._selectedTab = selectedTab
		self.allowsNavigation = allowsNavigation
	}

	var body: some View {
		VStack {
			if let pfpUrl = user.profilePicture {
				if MockAPIService.isMocking {
					Image(pfpUrl)
						.ProfileImageModifier(imageType: .activityParticipants)
				} else {
					CachedProfileImage(
						userId: user.id,
						url: URL(string: pfpUrl),
						imageType: .activityParticipants
					)
				}
			} else {
				Circle()
					.fill(Color.gray)
					.frame(width: width, height: height)
			}
		}
		.onTapGesture {
			guard allowsNavigation else { return }

			if isCurrentUser && selectedTab != nil {
				// Navigate to profile tab for current user
				selectedTab = .profile
			} else {
				// Show full screen cover for other users
				showProfile = true
			}
		}
		.fullScreenCover(isPresented: $showProfile) {
			UserProfileView(user: user)
		}
	}
}
