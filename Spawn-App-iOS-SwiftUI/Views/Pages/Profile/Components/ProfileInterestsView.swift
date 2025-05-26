//
//  ProfileInterestsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileInterestsView: View {
    let user: Nameable
    @StateObject var profileViewModel: ProfileViewModel
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
        ZStack(alignment: .top) {
            // Interests content
            Group {
                if profileViewModel.isLoadingInterests {
                    interestsLoadingView
                } else {
                    interestsContentView
                }
            }
            .padding(.top, 24)  // Add padding to push content below the header

            // Position the header to be centered on the top border
            interestsSectionHeader
                .padding(.leading, 6)
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
        .padding(.horizontal)
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
                .background(Color.white.opacity(0.5).cornerRadius(15))

            if profileViewModel.userInterests.isEmpty {
                emptyInterestsView
            } else {
                // Interests as chips with proper layout
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        // Use a simple LazyVGrid for consistent layout
                        LazyVGrid(
                            columns: [
                                GridItem(
                                    .adaptive(minimum: 80, maximum: 150),
                                    spacing: 4
                                )
                            ],
                            alignment: .leading,
                            spacing: 4
                        ) {
                            ForEach(profileViewModel.userInterests, id: \.self)
                            { interest in
                                interestChip(interest: interest)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(height: profileViewModel.userInterests.isEmpty ? 80 : 120)
        .padding(.horizontal)
        .padding(.top, 5)
    }

    private var emptyInterestsView: some View {
        Text("No interests added yet.")
            .foregroundColor(.gray)
            .italic()
            .padding()
            .padding(.top, 12)
    }

    private func interestChip(interest: String) -> some View {
        Text(interest)
			.font(.onestSemiBold(size: 12))
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .foregroundColor(universalAccentColor)
			.lineLimit(1)
            .background(Color.white)
            .clipShape(Capsule())
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
    }
}

#Preview {
    ProfileInterestsView(
        user: BaseUserDTO.danielAgapov,
		profileViewModel: ProfileViewModel(userId: BaseUserDTO.danielAgapov.id),
        editingState: .constant(.edit),
        newInterest: .constant(""),
        openSocialMediaLink: { _, _ in },
        removeInterest: { _ in }
    )
} 
