//
//  ProfileView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//
//  LEGACY WRAPPER: This view now routes to MyProfileView or UserProfileView
//  based on whether the user is viewing their own profile or someone else's.
//  Use MyProfileView or UserProfileView directly for new code.
//

import SwiftUI

/// Legacy wrapper view that routes to the appropriate profile view
/// For own profile: routes to MyProfileView
/// For other users: routes to UserProfileView
@available(*, deprecated, message: "Use MyProfileView for own profile or UserProfileView for other users directly")
struct ProfileView: View {
	let user: Nameable
	@ObservedObject var userAuth = UserAuthViewModel.shared

	// Check if this is the current user's profile
	private var isCurrentUserProfile: Bool {
		if MockAPIService.isMocking {
			return true
		}
		guard let currentUser = userAuth.spawnUser else { return false }
		return currentUser.id == user.id
	}

	var body: some View {
		Group {
			if isCurrentUserProfile, let currentUser = userAuth.spawnUser {
				MyProfileView(user: currentUser)
			} else {
				UserProfileView(user: user)
			}
		}
	}
}

@available(iOS 17, *)
#Preview {
	ProfileView(user: BaseUserDTO.danielAgapov)
}
