//
//  ProfileInterestsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileInterestsView: View {
    let user: Nameable
    @ObservedObject var profileViewModel: ProfileViewModel
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
        VStack(alignment: .leading, spacing: 12) {
            // Interests section header
            interestsSectionHeader
            
            // Interests content
            Group {
                if profileViewModel.isLoadingInterests {
                    interestsLoadingView
                } else {
                    interestsContentView
                }
            }
        }
    }

    private var interestsSectionHeader: some View {
        HStack {
            Text("Interests + Hobbies")
				.font(.onestBold(size: 14))
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(figmaBittersweetOrange)
                .cornerRadius(12)

            Spacer()

            // Social media icons
            if !profileViewModel.isLoadingSocialMedia {
                socialMediaIcons
            }
        }
        .padding(.horizontal, 22)
    }

    private var socialMediaIcons: some View {
        HStack(spacing: 10) {
            if let whatsappLink = profileViewModel.userSocialMedia?
                .whatsappLink, !whatsappLink.isEmpty
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

    private var interestsLoadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }

    private var interestsContentView: some View {
        ZStack(alignment: .topLeading) {
            // Background for interests section
            RoundedRectangle(cornerRadius: 15)
                .stroke(figmaBittersweetOrange, lineWidth: 1)
                .background(universalBackgroundColor.opacity(0.5).cornerRadius(15))

            if profileViewModel.userInterests.isEmpty {
                emptyInterestsView
            } else {
                // Interests as chips with simple layout
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(profileViewModel.userInterests, id: \.self) { interest in
                        interestChip(interest: interest)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .animation(.easeInOut(duration: 0.3), value: profileViewModel.userInterests)
            }
        }
        .frame(minHeight: 80)
        .padding(.horizontal)
    }

    private var emptyInterestsView: some View {
        Text("No interests added yet.")
            .foregroundColor(.secondary)
            .italic()
            .padding()
            .padding(.top, 12)
    }

    private func interestChip(interest: String) -> some View {
		Group{
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
						isCurrentUserProfile && editingState == .save
						? HStack {
							Spacer()
							Button(action: {
								removeInterest(interest)
							}) {
								Image(systemName: "xmark.circle.fill")
									.foregroundColor(.red)
									.font(.caption)
							}
							.offset(x: 5, y: -8)
						} : nil
					)
			} else {
				Text(interest)
					.font(.onestSemiBold(size: 12))
					.padding(.vertical, 6)
					.padding(.horizontal, 12)
					.foregroundColor(Color.primary)
					.lineLimit(1)
					.background(Color.gray.opacity(0.1))
					.clipShape(Capsule())
					.overlay(
						RoundedRectangle(cornerRadius: 20)
							.stroke(Color.gray.opacity(0.3), lineWidth: 1)
					)
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
