//
//  ProfilePictureView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/20/25.
//
import SwiftUI

struct ProfilePictureView: View {
    let user: BaseUserDTO
    let width: CGFloat = 28
    let height: CGFloat = 28
    @State var showProfile = false
    
    var body: some View {
        VStack {
            if let pfpUrl = user.profilePicture {
                if MockAPIService.isMocking {
                    Image(pfpUrl)
                        .ProfileImageModifier(imageType: .activityParticipants)
                } else {
                    AsyncImage(url: URL(string: pfpUrl)) { image in
                        image.ProfileImageModifier(imageType: .activityParticipants)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: width, height: height)
                    }
                }
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: width, height: height)
            }
        }
        .onTapGesture {
            showProfile = true
        }
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView(user: user)
        }
    }
}
