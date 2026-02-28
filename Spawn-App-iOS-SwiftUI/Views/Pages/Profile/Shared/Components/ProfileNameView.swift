//
//  ProfileNameView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileNameView: View {
	let user: Nameable
	@ObservedObject var userAuth = UserAuthViewModel.shared
	@Binding var refreshFlag: Bool

	// Figma: secondary text (e.g. @handle) — light gray in dark, gray700 in light
	private var usernameColor: Color {
		Color(
			UIColor { traitCollection in
				switch traitCollection.userInterfaceStyle {
				case .dark:
					return UIColor(Color(hex: colorsGray300))
				default:
					return UIColor(Color(hex: colorsGray700))
				}
			}
		)
	}

	// Check if this is the current user's profile
	var isCurrentUserProfile: Bool {
		if MockAPIService.isMocking {
			return true
		}
		guard let currentUser = userAuth.spawnUser else { return false }
		return currentUser.id == user.id
	}

	var body: some View {
		VStack(spacing: 4) {
			if isCurrentUserProfile,
				let currentUser = userAuth.spawnUser
			{
				Text(
					FormatterService.shared.formatName(
						user: currentUser
					)
				)
				.font(.onestBold(size: 24))
				.foregroundColor(universalAccentColor)
				Text("@\(currentUser.username ?? "username")")
					.font(.onestRegular(size: 16))
					.foregroundColor(usernameColor)
			} else {
				Text(
					FormatterService.shared.formatName(
						user: user
					)
				)
				.font(.onestBold(size: 24))
				.foregroundColor(universalAccentColor)
				Text("@\(user.username ?? "username")")
					.font(.onestRegular(size: 16))
					.foregroundColor(usernameColor)
			}
		}
		.id(refreshFlag)
	}
}

#Preview {
	ProfileNameView(
		user: BaseUserDTO.danielAgapov,
		refreshFlag: .constant(false)
	)
}
