//
//  FriendRequestView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI

struct FriendRequestView: View {
    @ObservedObject var viewModel: FriendRequestViewModel
    
    let user: User
    
    init(user: User, friendRequestId: UUID) {
        self.user = user
        self.viewModel = FriendRequestViewModel(apiService: MockAPIService.isMocking ? MockAPIService() : APIService(), userId: user.id, friendRequestId: friendRequestId)
    }

    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center, spacing: 12) {
                    // UI, using `user.` properties like: profile picture, username, and name
                    
                    // call buttons that you make
                    
                    // TODO SHANNON
                    
                    Text(user.username)
                    Text(FormatterService.shared.formatName(user: user))
                    Text(user.bio ?? "")
                    FriendRequestAcceptButton()
                    FriendRequestDeclineButton()
                }
                .padding(32)
                .background(universalBackgroundColor)
                .cornerRadius(universalRectangleCornerRadius)
                .shadow(radius: 10)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .scrollDisabled(true)
        }
    }
}
// TODO: grab friend's profile pic
// TODO: grab friend's username
// TODO: grab friend's name
//
struct FriendRequestAcceptButton: View {
    var body: some View {
        Button(action: {
            // TODO DANIEL
        }) {
            Text("accept")
            // TODO SHANNON
        }
    }
}
//
struct FriendRequestDeclineButton: View {
    var body: some View {
        Button(action: {
            // TODO DANIEL
        }) {
            Text("decline")
            // TODO SHANNON
        }
        
    }
}
