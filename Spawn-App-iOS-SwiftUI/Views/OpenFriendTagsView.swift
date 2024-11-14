//
//  OpenFriendTagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct OpenFriendTagsView: View {
    var body: some View {
        VStack (spacing: 16){
            // The small black bar
            RoundedRectangle(cornerRadius: 2)
                .frame(width: 120, height: 4)
                .foregroundColor(.black)
                .padding(.top, 20)
            Spacer()
            OpenFriendTagsView_ButtonView(type: .friends)
            OpenFriendTagsView_ButtonView(type: .tags)
            Spacer()
        }
        .background(universalBackgroundColor)
        .cornerRadius(universalRectangleCornerRadius)
        .frame(maxWidth: .infinity, maxHeight: 250)
    }
}

struct OpenFriendTagsView_ButtonView: View {
    var type: OpenFriendTagButtonType
    
    var body: some View {
        Button(action: {
            // TODO: implement navigation to go to either destination, based on `type`
        }) {
            Text("View \(type.getDisplayName())")
                .font(.title2)
                .foregroundColor(universalBackgroundColor)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
                        .fill(universalAccentColor)
                )
        }
        .padding(.horizontal, 60)
    }
}
