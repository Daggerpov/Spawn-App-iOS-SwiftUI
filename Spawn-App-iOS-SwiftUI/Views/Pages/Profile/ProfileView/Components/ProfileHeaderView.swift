//
//  ProfileHeaderView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI
import PhotosUI

struct ProfileHeaderView: View {
    let user: Nameable
    @ObservedObject var userAuth = UserAuthViewModel.shared
    
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    @Binding var isImageLoading: Bool
    @Binding var editingState: ProfileEditText
    
    // Check if this is the current user's profile
    var isCurrentUserProfile: Bool {
        if MockAPIService.isMocking {
            return true
        }
        guard let currentUser = userAuth.spawnUser else { return false }
        return currentUser.id == user.id
    }
    
    var body: some View {
        VStack {
            // Profile Picture
            profilePictureSection

            // Name and Username
            nameAndUsernameView
        }
    }
    
    private var profilePictureSection: some View {
        ZStack(alignment: .bottomTrailing) {
            if isImageLoading {
                ProgressView()
                    .frame(width: 128, height: 128)
            } else if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 128, height: 128)
                    .clipShape(Circle())
                    .transition(.opacity)
                    .id("selectedImage-\(UUID().uuidString)")
            } else if let profilePictureString = user.profilePicture {
                if MockAPIService.isMocking {
                    Image(profilePictureString)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 128, height: 128)
                        .clipShape(Circle())
                } else {
                    CachedProfileImageFlexible(
                        userId: user.id,
                        url: URL(string: profilePictureString),
                        width: 128,
                        height: 128
                    )
                    .transition(.opacity.animation(.easeInOut))
                    .id("profilePicture-\(profilePictureString)")
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .foregroundColor(Color.gray.opacity(0.5))
            }

            // Only show the plus button for current user's profile when in edit mode
            if isCurrentUserProfile && editingState == .save {
                Circle()
                    .fill(profilePicPlusButtonColor)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                    )
                    .offset(x: -10, y: -10)
                    .onTapGesture {
                        showImagePicker = true
                    }
            }
        }
    }
    
    private var nameAndUsernameView: some View {
        // Name and Username - make this more reactive to changes
        Group {
			if isCurrentUserProfile, let currentUser = userAuth.spawnUser
			{
				// For the current user, always display the latest from userAuth	                EmptyView()
				Text(
					FormatterService.shared.formatName(
						user: currentUser
					)
				)
				.font(.onestBold(size: 24))
				.foregroundColor(universalAccentColor)

									Text("@\(currentUser.username ?? "username")")
					.font(.onestRegular(size: 16))
					.foregroundColor(figmaBlack400)
					.padding(.bottom, 5)
            } else {
                // For other users, use the passed-in user
                Text(
                    FormatterService.shared.formatName(
                        user: user
                    )
                )
				.font(.onestBold(size: 24))
                .foregroundColor(universalAccentColor)

                					Text("@\(user.username ?? "username")")
					.font(.onestRegular(size: 16))
					.foregroundColor(figmaBlack400)
                    .padding(.bottom, 5)
            }
        }
    }
}

#Preview {
    ProfileHeaderView(
		user: BaseUserDTO.danielAgapov,
        selectedImage: .constant(nil),
        showImagePicker: .constant(false),
        isImageLoading: .constant(false),
        editingState: .constant(.edit)
    )
} 
