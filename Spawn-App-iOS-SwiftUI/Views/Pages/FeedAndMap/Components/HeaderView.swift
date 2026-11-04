//
//  HeaderView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/23/24.
//

import SwiftUI

struct HeaderView: View {
	var user: BaseUserDTO
	@ObservedObject private var userAuth = UserAuthViewModel.shared
	@State private var displayUser: BaseUserDTO

	init(user: BaseUserDTO) {
		self.user = user
		self._displayUser = State(initialValue: user)
	}

	var body: some View {
		// Figma Event Feed (node 2802:4741): avatar to the left of the greeting, navy text
		HStack(spacing: 16) {
			CachedProfileImage(
				userId: currentUser.id,
				url: URL(string: currentUser.profilePicture ?? ""),
				imageType: .friendsListView
			)
			Text("Hey \(currentDisplayName)! 👋")
				.font(.onestBold(size: 32))
				.foregroundColor(universalHeadingColor)
				.lineLimit(1)
				.minimumScaleFactor(0.7)
			Spacer()
		}
		.onAppear {
			updateDisplayUser()
		}
		.onReceive(NotificationCenter.default.publisher(for: .profileUpdated)) { notification in
			// Only update if this is the current user's profile update
			if let updatedUser = notification.userInfo?["updatedUser"] as? BaseUserDTO,
				updatedUser.id == user.id
			{
				displayUser = updatedUser
			}
		}
		.onReceive(userAuth.$spawnUser) { newUser in
			// Update if the current user's data changes
			if let currentUser = newUser, currentUser.id == user.id {
				displayUser = currentUser
			}
		}
	}

	/// The most up-to-date user data: the latest from userAuth when this is the current user
	private var currentUser: BaseUserDTO {
		if let authUser = userAuth.spawnUser, authUser.id == user.id {
			return authUser
		}
		return displayUser
	}

	private var currentDisplayName: String {
		currentUser.name?.components(separatedBy: " ").first ?? currentUser.username ?? "User"
	}

	private func updateDisplayUser() {
		// If this is the current user, use the latest from userAuth
		if let currentUser = userAuth.spawnUser, currentUser.id == user.id {
			displayUser = currentUser
		}
	}
}

@available(iOS 17, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared
	HeaderView(user: BaseUserDTO.danielAgapov).environmentObject(
		appCache
	)
}
