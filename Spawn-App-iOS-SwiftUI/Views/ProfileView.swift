//
//  ProfileView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileView: View {
    var user: User
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Profile Picture
                    
                    if let profilePicture = User.profilePicture {
                        profilePicture
                            .ProfileImageModifier(imageType: .profilePage)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .ProfileImageModifier(imageType: .profilePage)
                    }
                    
                    // Username
                    Text("Username: \(User.username)")
                        .font(.title)
                        .bold()
                    
                    Text(NameFormatterService.shared.formatName(user: User))
                        .font(.headline)
                    
                    
                    // Bio
                    if let bio = User.bio {
                        Text("Bio: \(bio)")
                            .font(.body)
                    }
                    
                    // Friend Tags
                    if let friendTags = User.friendTags, !friendTags.isEmpty {
                        Text("Friend Tags:")
                            .font(.headline)
                        ForEach(friendTags) { tag in
                            HStack {
                                Circle()
                                    .fill(tag.color)
                                    .frame(width: 10, height: 10)
                                Text(tag.displayName)
                            }
                        }
                    }
                    
                    // Last Location
                    if let lastLocation = User.lastLocation {
                        Text("Last Location: \(lastLocation.locationName)")
                            .font(.subheadline)
                    }
                }
                .padding()
                .navigationTitle("\(User.firstName ?? User.username)'s Profile")
            }
        }
    }
}
