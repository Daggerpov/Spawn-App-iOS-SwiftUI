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
					if MockAPIService.isMocking {
						Image(profilePictureString)
							.ProfileImageModifier(imageType: .feedPage)
					} else {
							AsyncImage(url: URL(string: profilePictureString)) { image in
								image
									.ProfileImageModifier(imageType: .feedPage)
							} placeholder: {
								Circle()
									.fill(Color.gray)
							}
						}
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
}
