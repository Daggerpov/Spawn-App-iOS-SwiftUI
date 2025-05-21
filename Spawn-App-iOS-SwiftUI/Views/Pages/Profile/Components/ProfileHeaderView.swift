//
//  ProfileHeaderView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Lee on 11/09/24.
//

import SwiftUI

struct ProfileHeaderView: View {
    let user: BaseUserDTO
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    @Binding var isImageLoading: Bool
    let isCurrentUserProfile: Bool
    let editingState: ProfileEditText
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isImageLoading {
                ProgressView()
                    .frame(width: 130, height: 130)
            } else if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
                    .transition(.opacity)
                    .id("selectedImage-\(UUID().uuidString)")
            } else if let profilePictureString = user.profilePicture {
                if MockAPIService.isMocking {
                    Image(profilePictureString)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                } else {
                    AsyncImage(url: URL(string: profilePictureString)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 130, height: 130)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 130, height: 130)
                                .clipShape(Circle())
                                .transition(.opacity.animation(.easeInOut))
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 130, height: 130)
                                .foregroundColor(Color.gray.opacity(0.5))
                        @unknown default:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 130, height: 130)
                                .foregroundColor(Color.gray.opacity(0.5))
                        }
                    }
                    .id("profilePicture-\(profilePictureString)")
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
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
        .animation(.easeInOut, value: selectedImage != nil)
        .animation(.easeInOut, value: isImageLoading)
        .sheet(
            isPresented: $showImagePicker,
            onDismiss: {
                // Only show loading if we actually have a new image
                if selectedImage != nil {
                    DispatchQueue.main.async {
                        isImageLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isImageLoading = false
                        }
                    }
                }
            }
        ) {
            SwiftUIImagePicker(selectedImage: $selectedImage)
                .ignoresSafeArea()
        }
        .onChange(of: selectedImage) { newImage in
            if newImage != nil {
                // Force UI update when image changes
                DispatchQueue.main.async {
                    isImageLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isImageLoading = false
                    }
                }
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
        isCurrentUserProfile: true,
        editingState: .edit
    )
} 