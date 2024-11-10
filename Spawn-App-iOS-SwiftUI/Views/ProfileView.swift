//
//  ProfileView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileView: View {
    var appUser: AppUser
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Profile Picture
                    if let profilePicture = appUser.profilePicture {
                        profilePicture
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .ProfileImageModifier(imageType: .profilePage)
                    }
                    
                    // Username
                    Text("Username: \(appUser.username)")
                        .font(.title)
                        .bold()
                    
                    // Full Name
                    if let firstName = appUser.firstName, let lastName = appUser.lastName {
                        Text("Full Name: \(firstName) \(lastName)")
                            .font(.headline)
                    } else if let firstName = appUser.firstName {
                        Text("First Name: \(firstName)")
                            .font(.headline)
                    } else if let lastName = appUser.lastName {
                        Text("Last Name: \(lastName)")
                            .font(.headline)
                    }
                    
                    // Bio
                    if let bio = appUser.bio {
                        Text("Bio: \(bio)")
                            .font(.body)
                    }
                    
                    // Friend Tags
                    if let friendTags = appUser.friendTags, !friendTags.isEmpty {
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
                    if let lastLocation = appUser.lastLocation {
                        Text("Last Location: \(lastLocation.locationName)")
                            .font(.subheadline)
                    }
                }
                .padding()
                .navigationTitle("\(appUser.firstName ?? appUser.username)'s Profile")
            }
        }
    }
}
