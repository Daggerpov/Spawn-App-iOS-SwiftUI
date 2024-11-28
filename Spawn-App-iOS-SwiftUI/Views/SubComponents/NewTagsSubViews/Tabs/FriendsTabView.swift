//
//  FriendsTabView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct FriendsTabView: View {
//    let user: User
    @ObservedObject var viewModel: FriendsListViewModel
    @EnvironmentObject var user: ObservableUser
    
    init(user: User) {
        self.viewModel = FriendsListViewModel(user: user)
    }
    
    var body: some View {
        SearchView(searchPlaceholderText: "search or add friends")
        ScrollView{
            VStack{
                VStack(alignment: .leading, spacing: 15) {
                    Text("requests")
                        .font(.headline)
                }
                Spacer()
                Spacer()
                
                
            }
            VStack{
                VStack(alignment: .leading, spacing: 15) {
                    Text("recommended friends")
                        .font(.headline)
                }
                Spacer()
                Spacer()
                
                
            }
            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.recommendedFriends) { recommendedFriend in
                    FriendListingView(person: recommendedFriend, user: user.user, isFriend: false)
                }
            }
            VStack{
                VStack(alignment: .leading, spacing: 15) {
                    Text("friends")
                        .font(.headline)
                    ForEach(viewModel.friends) { friend in
                        FriendListingView(person: friend, user: user.user, isFriend: true)
                    }
                }
                Spacer()
                Spacer()
                
                
            }
        }
        .padding()
    }
}
