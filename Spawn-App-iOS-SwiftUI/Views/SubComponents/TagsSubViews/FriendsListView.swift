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
        VStack {
            // TODO: implement searching by friend username or either name
            searchView
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Title and Time Information
                    ForEach(viewModel.friends) { friend in
                        FriendListingView(friend: friend)
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
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").font(.title3)
                TextField("Search", text: $viewModel.searchText)
                // TODO: implement an onchange to filter the users by search text:
//                    .onChange(of: viewModel.searchText) { _ in
//                        viewModel.loadQuotesBySearch()
//                    }
            }
            .foregroundColor(universalBackgroundColor)
            .padding(.vertical, 20)
            .padding(.horizontal, 15)
            .frame(height: 45)
            .background{
                RoundedRectangle(cornerRadius: 25).fill(.background)
                    .foregroundColor(universalBackgroundColor)
            }
        }
        .padding(.vertical, 20)
    }
}
