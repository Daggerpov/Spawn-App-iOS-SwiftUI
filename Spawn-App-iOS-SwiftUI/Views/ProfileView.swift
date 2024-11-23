//
//  ProfileView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileView: View {
    let user: User
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Profile Picture
                    
                    if let profilePictureString = user.profilePicture {
                        Image(profilePictureString)
                            .ProfileImageModifier(imageType: .profilePage)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .ProfileImageModifier(imageType: .profilePage)
                    }
                    
                    // Username
                    Text("Username: \(user.username)")
                        .font(.title)
                        .bold()
                    
                    Text(NameFormatterService.shared.formatName(user: user))
                        .font(.headline)
                    
                    
                    // Bio
                    if let bio = user.bio {
                        Text("Bio: \(bio)")
                            .font(.body)
                    }
                    
                    // Friend Tags
                    if let friendTags = user.friendTags, !friendTags.isEmpty {
                        Text("Friend Tags:")
                            .font(.headline)
                        ForEach(friendTags) { tag in
                            HStack {
                                Circle()
                                    .fill(Color(hex: tag.colorHexCode))
                                    .frame(width: 10, height: 10)
                                Text(tag.displayName)
                            }
                        }
                    }
                    
                }
                .padding()
                .navigationTitle("\(user.firstName ?? user.username)'s Profile")
            }
        }
    }
}
