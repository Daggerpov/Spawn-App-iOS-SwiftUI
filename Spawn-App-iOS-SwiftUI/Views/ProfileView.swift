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
                VStack(alignment: .center, spacing: 20) {
                    // Profile Picture
                    
                    if let profilePictureString = user.profilePicture {
                        Image(profilePictureString)
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
                       ProfileField(label: "Name", value: "\(user.firstName ?? "") \(user.lastName ?? "")")
                       ProfileField(label: "Username", value: user.username)
                       ProfileField(label: "Email", value: user.email)
                       BioField(label: "Bio", bio: Binding(
                           get: { user.bio ?? "" },
                           set: { user.bio = $0 }
                       ))
                   }
                   .padding(.horizontal)
                    
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
                }
                .padding()
            }
            .background(universalBackgroundColor)
        }
    }
}


struct ProfileField: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .frame(width: 100, alignment: .leading)
            Spacer()
            Text(value)
                .font(.body)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct BioField: View {
    let label: String
    @Binding var bio: String

    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .frame(width: 80, alignment: .leading)
            Spacer()
            TextField(
                "",
                text: $bio,
                prompt: Text("Bio")
                    .foregroundColor(universalPlaceHolderTextColor)
            )
            .multilineTextAlignment(.trailing)
            .font(.body)
        }
    }
}
