//
//  BottomNavButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct BottomNavButtonView: View {
    var buttonType: BottomNavButtonType
    var imageName: String
    var imageSize: CGFloat = 25
    
    init(buttonType: BottomNavButtonType) {
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
    }
    
    var body: some View {
        if buttonType == .map {
            Circle()
                .frame(width: 45, height: 45)
                .foregroundColor(universalBackgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(universalAccentColor, lineWidth: 2)
                )
                .overlay(
                    Group{
                        if buttonType == .map {
                            NavigationLink(destination: {
                                FriendMapView()
                            }) {
                                navButtonImage
                            }
                        } else {
                            navButtonImage
                        }
                    }
                )
        } else if buttonType == .feed || buttonType == .friends {
            Circle()
                .CircularButton(systemName: imageName, buttonActionCallback: {
                    print("clicked!")
                    // TODO: change to navigation later
                }, width: 25, height: 20, frameSize: 45, source: "map")
            
        } else if buttonType == .plus {
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 100, height: 45)
                .foregroundColor(universalBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(universalAccentColor, lineWidth: 2)
                )
                .overlay(
                    NavigationLink(destination: {
                        FriendMapView()
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