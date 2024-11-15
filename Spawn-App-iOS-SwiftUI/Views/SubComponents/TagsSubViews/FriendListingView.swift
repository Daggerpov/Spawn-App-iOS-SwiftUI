//
//  FriendListingView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct FriendListingView: View {
    @ObservedObject var viewModel: FriendListingViewModel
    var person: AppUser
    
    init(person: AppUser, appUser: AppUser, isFriend: Bool) {
        self.person = person
        self.viewModel = FriendListingViewModel(person: person, appUser: appUser, isFriend: isFriend)
    }
    var body: some View {
        Group{
            if viewModel.isFriend {
                HStack{
                    if let pfp = person.profilePicture {
                        pfp
                            .ProfileImageModifier(imageType: .friendsListView)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .ProfileImageModifier(imageType: .friendsListView)
                    }
                    VStack{
                        HStack{
                            Image(systemName: "star.fill")
                            Text(person.username)
                                .bold()
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .font(.subheadline)
                        .foregroundColor(universalBackgroundColor)
                        HStack{
                            ForEach(viewModel.tagsForFriend) { friendTag in
                                // TODO: implement navigation from friend tag to friend tag view, which I'll do now, inside of "View Tags" popup
                                Text(friendTag.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .foregroundColor(.white) // Adjust text color if needed
                                    .background(
                                        Capsule()
                                            .fill(friendTag.color)
                                    )
                            }
                            Spacer()
                        }
                        .padding(.leading, 20)
                        
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(universalAccentColor)
                .cornerRadius(universalRectangleCornerRadius)
            } else {
                // not a friend
                HStack{
                    HStack{
                        if let pfp = person.profilePicture {
                            pfp
                                .ProfileImageModifier(imageType: .friendsListView)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .ProfileImageModifier(imageType: .friendsListView)
                        }
                        VStack{
                            HStack{
                                Image(systemName: "star.fill")
                                Text(person.username)
                                    .bold()
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.leading)
                            .font(.subheadline)
                            .foregroundColor(universalBackgroundColor)
                            HStack{
                                Text(viewModel.formattedFriendName)
                                    .bold()
                                    .padding(.horizontal)
                                    .padding(.vertical, 0.25)
                                    .font(.headline)
                                    .foregroundColor(universalBackgroundColor)
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(universalAccentColor)
                    .cornerRadius(universalRectangleCornerRadius)
                    Spacer()
                    Circle()
                        .CircularButton(systemName: "person.2.badge.plus.fill", buttonActionCallback: {
                            viewModel.addFriend()
                        }, width: 25, height: 20, frameSize: 45)
                        .padding(.leading, 10)
                }
            }
        }
    }
}
