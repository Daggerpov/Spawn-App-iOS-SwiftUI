//
//  ProfileActionButtonsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Lee on 11/09/24.
//

import SwiftUI

struct ProfileActionButtonsView: View {
    let user: BaseUserDTO
    let isCurrentUserProfile: Bool
    let profileViewModel: ProfileViewModel
    let shareProfile: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            if isCurrentUserProfile {
                NavigationLink(
                    destination: EditProfileView(
                        userId: user.id,
                        profileViewModel: profileViewModel
                    )
                ) {
                    HStack (spacing: 8){
                        Image(systemName: "pencil.circle")
                        Text("Edit Profile")
                            .bold()
                    }
                    .bold()
                    .font(.caption)
                    .foregroundColor(figmaSoftBlue)
                    .frame(height: 30)
                    .frame(width: 128)
                }
                .navigationBarBackButtonHidden(true)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(figmaSoftBlue, lineWidth: 1)
                )
            }

            Button(action: {
                shareProfile()
            }) {
                HStack (spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Profile")
                }
                .bold()
                .font(.caption)
                .foregroundColor(figmaSoftBlue)
                .frame(height: 30)
                .frame(width: 128)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(figmaSoftBlue, lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    ProfileActionButtonsView(
        user: BaseUserDTO.danielAgapov,
        isCurrentUserProfile: true,
        profileViewModel: ProfileViewModel(),
        shareProfile: {}
    )
} 
