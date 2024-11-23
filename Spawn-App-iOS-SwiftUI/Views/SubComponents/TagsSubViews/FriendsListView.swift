//
//  FriendsListView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct FriendsListView: View {
    @ObservedObject var viewModel: FriendsListViewModel
    @EnvironmentObject var user: ObservableUser
    
    init(user: User) {
        self.viewModel = FriendsListViewModel(user: user)
    }
    
    var body: some View {
        VStack {
            // TODO: implement searching by friend username or either name
            SearchView()
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Title and Time Information
                    ForEach(viewModel.friends) { friend in
                        FriendListingView(person: friend, user: user.user, isFriend: true)
                    }
                    ForEach(viewModel.recommendedFriends) { recommendedFriend in
                        FriendListingView(person: recommendedFriend, user: user.user, isFriend: false)
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
