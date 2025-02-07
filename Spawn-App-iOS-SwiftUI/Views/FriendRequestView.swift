//
//  FriendRequestView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI

struct FriendRequestView: View {
    
    let user: User
    
    init(user: User) {
        self.user = user
    }

    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center, spacing: 12) {
                    
                    
                }
                .padding(32)
                .background(universalBackgroundColor)
                .cornerRadius(universalRectangleCornerRadius)
                .shadow(radius: 10)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
// TODO: grab friend's profile pic
// TODO: grab friend's username
// TODO: grab friend's name
//
//struct FriendRequestAcceptButton: View {
//    
//}
//
//struct FriendRequestDeclineButton: View {
//    
//}
