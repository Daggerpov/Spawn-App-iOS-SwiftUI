//
//  FriendsListView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct FriendsListView: View {
    @ObservedObject var viewModel: FriendsListViewModel
    
    init(appUser: AppUser) {
        self.viewModel = FriendsListViewModel(appUser: appUser)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title and Time Information
                ForEach(viewModel.friends) { friend in
                    Text(friend.username)
                }
            }
            .padding(20)
            .background(universalAccentColor)
            .cornerRadius(universalRectangleCornerRadius)
        }
        .padding(.horizontal) // Reduces padding on the bottom
        .padding(.top, 200)
    }
}
