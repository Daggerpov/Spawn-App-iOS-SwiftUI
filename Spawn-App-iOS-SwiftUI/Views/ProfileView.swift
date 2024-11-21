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
                VStack(alignment: .center, spacing: 20) {
                    // Profile Picture
                    
                    if let profilePicture = appUser.profilePicture {
                        profilePicture
                            .ProfileImageModifier(imageType: .profilePage)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(universalAccentColor, lineWidth: 2))
                        
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .ProfileImageModifier(imageType: .profilePage)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(universalAccentColor, lineWidth: 2))
                    }
                                            
                    Circle()
                        .fill(profilPicPlusButtonColor)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "plus")
                                .foregroundColor(addButtonColor)
                        )
                        .offset(x: 45, y: -45)
                    
                    VStack(alignment: .leading, spacing: 25) {
                          HStack {
                              Text("Name")
                                  .font(.headline)
                              Spacer()
                              Text("\(appUser.firstName ?? "") \(appUser.lastName ?? "")")
                                  .multilineTextAlignment(.leading)
                                  .font(.headline)
                          }
                          HStack {
                              Text("Username")
                                  .font(.headline)
                              Spacer()
                              Text(appUser.username)
                                  .multilineTextAlignment(.leading)
                                  .font(.headline)
                          }
                          HStack {
                              Text("Email")
                                  .font(.headline)
                              Spacer()
                              Text(appUser.email)
                                  .multilineTextAlignment(.leading)
                                  .font(.headline)
                          }
                          HStack {
                              Text("Bio")
                                  .font(.headline)
                              Spacer()
                              TextField(
                                      "",
                                      text: Binding(
                                          get: { appUser.bio ?? "" },
                                          set: { appUser.bio = $0 }
                                      ),
                                      prompt: Text("Bio")
                                          .foregroundColor(universalPlaceHolderTextColor)
                                  )
                                  .multilineTextAlignment(.leading)
                                  .font(.headline)
                          }
                      }
                    .padding(.horizontal, 15)
                    
                    Spacer()
                    Divider().background(universalAccentColor)
                    Spacer()
                    
                    // Edit Button
                    Button(action: {
                        // Edit button action
                    }) {
                        Text("Edit")
                            .font(.headline)
                            .foregroundColor(universalAccentColor)
                            .frame(maxWidth: 135)
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

                    // Logout Button
                    Button(action: {
                    }) {
                        Text("Log Out")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: 170)
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
            .background(universalBackgroundColor)
        }
    }
}
