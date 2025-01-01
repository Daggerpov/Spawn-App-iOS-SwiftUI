//
//  BottomNavButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct BottomNavButtonView: View {
    @EnvironmentObject var user: ObservableUser
    var buttonType: BottomNavButtonType
    var imageName: String
    var imageSize: CGFloat = 25
	let source: BackButtonSourcePageType

	init(buttonType: BottomNavButtonType, source: BackButtonSourcePageType = .feed) {
        self.buttonType = buttonType
        switch(buttonType) {
            case .map:
                self.imageName = "map.fill"
            case .plus:
                self.imageName = "plus"
            case .friends:
                self.imageName = "person.2.fill"
            case .feed:
                self.imageName = "list.bullet"
                self.imageSize = 12
        }
		self.source = source
    }
    
    var body: some View {
        switch buttonType {
            case .map:
                Circle()
                    .frame(width: 45, height: 45)
                    .foregroundColor(universalBackgroundColor)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(universalAccentColor, lineWidth: 2)
                    )
                    .overlay(
                        NavigationLink(destination: {
                            MapView()
                                .navigationBarTitle("")
                                .navigationBarHidden(true)
                        }) {
                            navButtonImage
                        }
                    )
            case .feed:
                Circle()
                    .modifier(CircularButtonStyling(
                        width: 25,
                        height: 20,
                        frameSize: 45,
                        source: "map"
                    ))
                    .overlay(
                        NavigationLink(destination: {
                            FeedView()
                                .navigationBarTitle("")
                                .navigationBarHidden(true)
                        }) {
                            Image(systemName: imageName)
                                .resizable()
                                .frame(width: 25, height: 20)
                                .shadow(radius: 20)
                                .foregroundColor(universalAccentColor)
                        }
                    )
            case .friends:
                Circle()
                    .modifier(CircularButtonStyling(width: 25, height: 20, frameSize: 45, source: "map"))
                    .overlay(
                        NavigationLink(destination: {
							FriendsView(user: user.user, source: source)
                                .navigationBarTitle("")
                                .navigationBarHidden(true)
                        }) {
                            Image(systemName: imageName)
                                .resizable()
                                .frame(width: 25, height: 20)
                                .shadow(radius: 20)
                                .foregroundColor(universalAccentColor)
                        }
                    )
            case .plus:
                RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
                    .frame(width: 100, height: 45)
                    .foregroundColor(universalBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
                            .stroke(universalAccentColor, lineWidth: 2)
                    )
                    .overlay(
                        NavigationLink(destination: {
                            MapView()
                                .navigationBarTitle("")
                                .navigationBarHidden(true)
                        }) {
                            HStack{
                                Spacer()
                                Image(systemName: imageName)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .clipShape(Circle())
                                    .shadow(radius: 20)
                                    .foregroundColor(universalAccentColor)
                                    .font(.system(size: 30, weight: .bold)) // Added font modifier for thickness, to match Figma design
                                Spacer()
                            }
                        }
                    )
        }
    }
}

extension BottomNavButtonView {
    var navButtonImage: some View {
        Image(systemName: imageName)
            .resizable()
            .frame(width: imageSize, height: imageSize)
            .clipShape(Circle())
            .shadow(radius: 20)
            .foregroundColor(universalAccentColor)
    }
}
