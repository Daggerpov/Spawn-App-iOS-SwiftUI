//
//  FriendsListView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct FriendsListView: View {
    @ObservedObject var viewModel: FriendsListViewModel
    var appUser: AppUser
    
    init(appUser: AppUser) {
        self.appUser = appUser
        self.viewModel = FriendsListViewModel(appUser: appUser)
    }
    
    var body: some View {
        VStack {
            // TODO: implement searching by friend username or either name
            searchView
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Title and Time Information
                    ForEach(viewModel.friends) { friend in
                        FriendListingView(person: friend, appUser: appUser, isFriend: true)
                    }
                    ForEach(viewModel.recommendedFriends) { recommendedFriend in
                        FriendListingView(person: recommendedFriend, appUser: appUser, isFriend: false)
                    }
                }
            }
        }
        .padding()
        .background(universalBackgroundColor)
        .padding(.horizontal)
        .padding(.top, 200)
    }
}

extension FriendsListView {
    var searchView: some View {
        VStack{
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundColor(universalAccentColor)
                TextField("Search", text: $viewModel.searchText)
                    .foregroundColor(universalAccentColor)
                    .placeholderColor(universalAccentColor)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 15)
            .frame(height: 45)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(universalAccentColor, lineWidth: 2)
            )
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(universalBackgroundColor)
            )
        }
        .padding(.vertical, 20)
    }
}
