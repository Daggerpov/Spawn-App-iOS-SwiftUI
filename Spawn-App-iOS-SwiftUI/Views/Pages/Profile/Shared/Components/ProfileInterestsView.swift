//
//  ProfileInterestsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileInterestsView: View {
	let user: Nameable
	var profileViewModel: ProfileViewModel
	@Binding var editingState: ProfileEditText
	@Binding var newInterest: String

	var openSocialMediaLink: (String, String) -> Void
	var removeInterest: (String) -> Void

	// Check if this is the current user's profile
	var isCurrentUserProfile: Bool {
		if MockAPIService.isMocking {
			return true
		}
		guard let currentUser = UserAuthViewModel.shared.spawnUser else { return false }
		return currentUser.id == user.id
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			// Main content with overlaid header and social media icons
			Group {
				if profileViewModel.isLoadingInterests {
					interestsLoadingView
				} else {
					interestsContentView
				}
			}
		}
	}

	private var interestsLoadingView: some View {
		VStack(spacing: 0) {
			// Loading indicator
			ProgressView()
				.frame(maxWidth: .infinity, alignment: .center)
				.padding(.horizontal, 16)
				.padding(.top, 28)
				.padding(.bottom, 16)
		}
		.background(
			RoundedRectangle(cornerRadius: 15)
				.stroke(figmaBittersweetOrange, lineWidth: 1)
				.background(universalBackgroundColor.opacity(0.5).cornerRadius(15))
		)
		.overlay(alignment: .topLeading) {
			// Header positioned on the border
			HStack {
				Text("Interests + Hobbies")
					.font(.onestBold(size: 14))
                    .foregroundColor(.black)
					.padding(.vertical, 8)
					.padding(.horizontal, 12)
					.background(figmaBittersweetOrange)
					.cornerRadius(12)
					.offset(x: 16, y: -20)

				Spacer()

				// Social media icons
				if !profileViewModel.isLoadingSocialMedia {
					socialMediaIcons
						.offset(x: -16, y: -24)
				}
			}
		}
	}

	private var socialMediaIcons: some View {
		HStack(spacing: 10) {
			// Only show WhatsApp if it's the current user's profile OR they are friends
			if let whatsappLink = profileViewModel.userSocialMedia?
				.whatsappLink, !whatsappLink.isEmpty,
				isCurrentUserProfile || profileViewModel.friendshipStatus == .friends
			{
				Image("whatsapp")
					.resizable()
					.scaledToFit()
					.frame(width: 48, height: 48)
					.rotationEffect(.degrees(-8))
					.onTapGesture {
						openSocialMediaLink(
							"WhatsApp",
							whatsappLink
						)
					}
			}

			if let instagramLink = profileViewModel.userSocialMedia?
				.instagramLink, !instagramLink.isEmpty
			{
				Image("instagram")
					.resizable()
					.scaledToFit()
					.frame(width: 40, height: 40)
					.rotationEffect(.degrees(8))
					.onTapGesture {
						openSocialMediaLink(
							"Instagram",
							instagramLink
						)
					}
			}
		}
	}

	private var interestsContentView: some View {
		VStack(spacing: 0) {
			// Content area with dynamic height
			if profileViewModel.userInterests.isEmpty {
				emptyInterestsView
					.padding(.top, 28)
			} else {
				// Interests as chips with flexible layout
				LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
					ForEach(Array(profileViewModel.userInterests.enumerated()), id: \.offset) { index, interest in
						interestChip(interest: interest)
					}
				}
				.padding(.horizontal, 16)
				.padding(.top, 28)
				.padding(.bottom, 16)
				.animation(.easeInOut(duration: 0.3), value: profileViewModel.userInterests)
			}
		}
		.background(
			RoundedRectangle(cornerRadius: 15)
				.stroke(figmaBittersweetOrange, lineWidth: 1)
				.background(universalBackgroundColor.opacity(0.5).cornerRadius(15))
		)
		.overlay(alignment: .topLeading) {
			// Header positioned on the border
			HStack {
				Text("Interests + Hobbies")
					.font(.onestBold(size: 14))
                    .foregroundColor(Color(hex: colorsGray900))
					.padding(.vertical, 8)
					.padding(.horizontal, 12)
					.background(figmaBittersweetOrange)
					.cornerRadius(12)
					.offset(x: 16, y: -20)

				Spacer()

				// Social media icons
				if !profileViewModel.isLoadingSocialMedia {
					socialMediaIcons
						.offset(x: -16, y: -24)
				}
			}
		}
	}

	private var emptyInterestsView: some View {
		Text("No interests added yet.")
            .frame(maxWidth: .infinity)
			.foregroundColor(.secondary)
			.italic()
			.font(.onestRegular(size: 14))
			.padding(.horizontal, 16)
			.padding(.bottom, 25)
	}

	private func interestChip(interest: String) -> some View {
		Group {
			if isCurrentUserProfile && editingState == .save {
				Text(interest)
					.font(.onestSemiBold(size: 12))
					.padding(.vertical, 8)
					.padding(.horizontal, 14)
					.foregroundColor(Color.primary)
					.lineLimit(1)
					.background(universalBackgroundColor)
					.clipShape(Capsule())
					.overlay(
						RoundedRectangle(cornerRadius: 20)
							.stroke(figmaBittersweetOrange, lineWidth: 1)
					)
					.shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
					.overlay(
						HStack {
							Spacer()
							Button(action: {
								removeInterest(interest)
							}) {
								Image(systemName: "xmark.circle")
									.foregroundColor(.red)
									.font(.caption)
									.background(Color.white)
									.clipShape(Circle())
							}
							.offset(x: 5, y: -8)
						}
					)
			} else {
				Text(interest)
					.font(.onestSemiBold(size: 12))
					.padding(.vertical, 6)
					.padding(.horizontal, 12)
					.foregroundColor(Color.primary)
					.lineLimit(1)
			}
		}
	}
}

#Preview {
	ProfileInterestsView(
		user: BaseUserDTO.danielAgapov,
		profileViewModel: ProfileViewModel(),
		editingState: .constant(.edit),
		newInterest: .constant(""),
		openSocialMediaLink: { _, _ in },
		removeInterest: { _ in }
	)
}
