//
//  HeaderView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/23/24.
//

import SwiftUI

struct HeaderView: View {
    var user: User
    var body: some View {
        HStack{
            Spacer()
            VStack{
                HStack{
                    Text("hello,")
                        .font(.title)
                    Spacer()
                }
                
                HStack{
                    Image(systemName: "star.fill")
                    Text(user.username)
                        .bold()
                        .font(.largeTitle)
                    Spacer()
                }
                .font(.title)
            }
            .foregroundColor(universalAccentColor)
            .frame(alignment: .leading)
            Spacer()
            
            if let profilePictureString = user.profilePicture {
                NavigationLink {
                    ProfileView(user: user)
                } label: {
                    Image(profilePictureString)
                        .ProfileImageModifier(imageType: .feedPage)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
}
