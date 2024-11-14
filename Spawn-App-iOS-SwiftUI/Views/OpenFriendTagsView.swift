//
//  OpenFriendTagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct OpenFriendTagsView: View {
    var body: some View {
        VStack{
            Spacer()
            OpenFriendTagsView_ButtonView(type: .friends)
            OpenFriendTagsView_ButtonView(type: .tags)
            Spacer()
        }
        .background(backgroundColor)
        .cornerRadius(universalRectangleCornerRadius)
        .frame(maxWidth: .infinity, maxHeight: 275)
    }
}

struct OpenFriendTagsView_ButtonView: View {
    var type: OpenFriendTagButtonType
    
    var body: some View {
        HStack{
            Spacer()
            Text("View \(type.getDisplayName())")
                .font(.headline)
                .background(universalAccentColor)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(
                        cornerRadius: universalRectangleCornerRadius
                    )
                    .fill(.background)
                    .stroke(universalAccentColor)
                    .foregroundColor(universalAccentColor)
                )
            Spacer()
            // TODO: implement navigation to go to either destination, similar to `BottomNavButtonView`
            // -> base this on the `type`
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

