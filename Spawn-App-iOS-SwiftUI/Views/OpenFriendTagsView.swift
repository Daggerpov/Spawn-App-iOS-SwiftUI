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
            HStack{
                Spacer()
                Text("View Friends")
                Spacer()
            }
            HStack{
                Spacer()
                Text("View Tags")
                Spacer()
            }
            Spacer()
        }
        .background(backgroundColor)
        .cornerRadius(universalRectangleCornerRadius)
        .frame(maxWidth: .infinity, maxHeight: 275)
    }
}
