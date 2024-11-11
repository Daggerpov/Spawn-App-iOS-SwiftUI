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
    
    init(buttonType: BottomNavButtonType) {
        self.buttonType = buttonType
        switch(buttonType) {
            case .map:
                self.imageName = "map.fill"
            case .plus:
                self.imageName = "plus"
            case .tag:
                self.imageName = "tag.fill"
        }
    }
    
    var body: some View {
        if buttonType == .map || buttonType == .tag {
            Circle()
                .frame(width: 45, height: 45)
                .foregroundColor(Color(hex: "#C0BCB4"))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(hex: "#173131"), lineWidth: 2)
                )
                .overlay(
                    NavigationLink(destination: {
                        FriendMapView()
                    }) {
                        Image(systemName: imageName)
                            .resizable()
                            .frame(width: 25, height: 25)
                            .clipShape(Circle())
                            .shadow(radius: 20)
                            .foregroundColor(Color(hex: "#173131"))
                    }
                )
        } else if buttonType == .plus {
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 100, height: 45)
                .foregroundColor(Color(hex: "#C0BCB4"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "#173131"), lineWidth: 2)
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
                                .foregroundColor(Color(hex: "#173131"))
                                .font(.system(size: 30, weight: .bold)) // Added font modifier for thickness, to match Figma design
                            Spacer()
                        }
                    }
                )
        }
        
        
    }
}
