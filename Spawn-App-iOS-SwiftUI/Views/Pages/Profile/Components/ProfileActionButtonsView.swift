//
//  ProfileActionButtonsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileActionButtonsView: View {
    let user: Nameable
    @StateObject var userAuth = UserAuthViewModel.shared
    let shareProfile: () -> Void
    
    // Check if this is the current user's profile
    var isCurrentUserProfile: Bool {
        if MockAPIService.isMocking {
            return true
        }
        guard let currentUser = userAuth.spawnUser else { return false }
        return currentUser.id == user.id
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if isCurrentUserProfile {
                NavigationLink(
                    destination: EditProfileView(
                        userId: user.id,
                        profileViewModel: ProfileViewModel(userId: user.id)
                    )
                ) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Profile")
                            .bold()
                    }
                    .font(.caption)
                    .foregroundColor(universalSecondaryColor)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 8)
                    .frame(height: 32)
                    .frame(maxWidth: .infinity)
                }
                .navigationBarBackButtonHidden(true)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(universalSecondaryColor, lineWidth: 1)
                )
            }

            Button(action: {
                shareProfile()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Profile")
                        .bold()
                }
                .font(.caption)
                .foregroundColor(universalSecondaryColor)
                .padding(.vertical, 24)
                .padding(.horizontal, 8)
                .frame(height: 32)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(universalSecondaryColor, lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    ProfileActionButtonsView(
		user: BaseUserDTO.danielAgapov,
        shareProfile: {}
    )
} 
