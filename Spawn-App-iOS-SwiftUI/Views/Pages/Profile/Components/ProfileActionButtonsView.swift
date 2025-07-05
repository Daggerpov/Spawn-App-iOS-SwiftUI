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
        HStack(spacing: 8) {
            if isCurrentUserProfile {
                NavigationLink(
                    destination: EditProfileView(
                        userId: user.id,
                        profileViewModel: ProfileViewModel(userId: user.id)
                    )
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.circle")
                        Text("Edit Profile")
							.font(.onestSemiBold(size: 12))
                    }
                    .bold()
                    .font(.caption)
                    .foregroundColor(universalAccentColor)
                    .frame(height: 30)
                    .frame(width: 128)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(universalAccentColor, lineWidth: 1)
                    )
                }
                .navigationBarBackButtonHidden(true)
            }

            Button(action: {
                shareProfile()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Profile")
						.font(.onestSemiBold(size: 12))
                }
                .bold()
                .font(.caption)
                .foregroundColor(universalAccentColor)
                .frame(height: 30)
                .frame(width: 128)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(universalAccentColor, lineWidth: 1)
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
