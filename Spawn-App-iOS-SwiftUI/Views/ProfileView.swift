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
                            .ProfileImageModifier(imageType: .profilePage)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .ProfileImageModifier(imageType: .profilePage)
                    }
                    
                    Circle()
                        .fill(profilPicPlusButtonColor)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "plus")
                                .foregroundColor(addButtonColor)
                        )
                        
                    
                    Text("Name \(NameFormatterService.shared.formatName(appUser: appUser))")
                    
                    // Username
                    Text("Username \(appUser.username)")
                    
                    // Email
                    Text("Email \(appUser.email)")
            
                    // Bio
                    if let bio = appUser.bio {
                        Text("Bio \(bio)")
                            .font(.body)
                    }
                    
                    Divider().background(universalAccentColor)
                    
                    // Edit Button
                    Button(action: {
                        // Edit button action
                    }) {
                        Text("Edit")
                            .font(.headline)
                            .foregroundColor(universalAccentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)

                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()

                    // Logout Button
                    Button(action: {
                    }) {
                        Text("Log Out")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(profilPicPlusButtonColor)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal)
                    
                    
                    // commented out friend tags and last location for now as it's not included in the Figma Design
                    
                    // Friend Tags
//                    if let friendTags = appUser.friendTags, !friendTags.isEmpty {
//                        Text("Friend Tags:")
//                            .font(.headline)
//                        ForEach(friendTags) { tag in
//                            HStack {
//                                Circle()
//                                    .fill(tag.color)
//                                    .frame(width: 10, height: 10)
//                                Text(tag.displayName)
//                            }
//                        }
//                    }
                    
                    // Last Location
//                    if let lastLocation = appUser.lastLocation {
//                        Text("Last Location: \(lastLocation.locationName)")
//                            .font(.subheadline)
//                    }
                }
                .padding()
//                .navigationTitle("\(appUser.firstName ?? appUser.username)'s Profile")
            }
        }
    }
}
