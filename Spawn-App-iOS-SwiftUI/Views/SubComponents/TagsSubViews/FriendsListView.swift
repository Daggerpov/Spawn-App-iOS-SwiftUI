//
//  FriendsListView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct FriendsListView: View {
    @ObservedObject var viewModel: FriendsListViewModel
    var user: User
    
    init(user: User) {
        self.user = User
        self.viewModel = FriendsListViewModel(user: User)
    }
    
    var body: some View {
        VStack {
            // TODO: implement searching by friend username or either name
            SearchView()
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Title and Time Information
                    ForEach(viewModel.friends) { friend in
                        FriendListingView(person: friend, user: User, isFriend: true)
                    }
                    ForEach(viewModel.recommendedFriends) { recommendedFriend in
                        FriendListingView(person: recommendedFriend, user: User, isFriend: false)
                    }
                }
            }
			.padding(.horizontal)
        }

        .padding()
        .background(universalBackgroundColor)
		.overlay {
			RoundedRectangle(cornerRadius: 20)
				.stroke(universalBackgroundColor, lineWidth: 2)
		}
		.clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.top, 200)

    }
}
