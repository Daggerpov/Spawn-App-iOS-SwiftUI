//
//  FriendsListView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct FriendsListView: View {
    @ObservedObject var viewModel: FriendsListViewModel
    var User: User
    
    init(User: User) {
        self.User = User
        self.viewModel = FriendsListViewModel(User: User)
    }
    
    var body: some View {
        VStack {
            // TODO: implement searching by friend username or either name
            SearchView()
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Title and Time Information
                    ForEach(viewModel.friends) { friend in
                        FriendListingView(person: friend, User: User, isFriend: true)
                    }
                    ForEach(viewModel.recommendedFriends) { recommendedFriend in
                        FriendListingView(person: recommendedFriend, User: User, isFriend: false)
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
