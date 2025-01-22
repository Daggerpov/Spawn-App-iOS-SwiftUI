//
//  FriendsTabView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct FriendsTabView: View {
    @ObservedObject var viewModel: FriendsTabViewModel
    let user: User

    init(user: User) {
        self.user = user
        self.viewModel = FriendsTabViewModel(
            userId: user.id,
            apiService: MockAPIService.isMocking
            ? MockAPIService(userId: user.id) : APIService())
    }

    var body: some View {
        VStack {
            // add friends buttons

            // accept friend req buttons
                SearchView(searchPlaceholderText: "search or add friends")
        }
        requestsSection
        .onAppear {
            Task{
                await viewModel.fetchAllData()
            }
        }
        
    }
    
    var requestsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("requests")
                .font(.headline)
                .foregroundColor(universalAccentColor)
            ScrollView(.horizontal, showsIndicators: false) {
//                //TODO: figuring out how to display the requests as circles below the 'requests' text
                VStack(spacing: 12) {
//                    ForEach(user, id: \.id) { request in
//                        Image(request.imageName)
//                            .resizable()
//                            .frame(width: 50, height: 50)
//                            .clipShape(Circle())
//                            .overlay(Circle().stroke(universalAccentColor, lineWidth: 2))
//                    }
                }
            }
        }
    }
    
    //TODO: maybe a component for both recommended friends and friends?
    
    var recommendedFriendsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("recommended friends")
                .font(.headline)
                .foregroundColor(universalAccentColor)
            ScrollView(.horizontal, showsIndicators: false) {
//                //TODO: figuring out how to display recommended friends
                HStack(spacing: 12) {
//                    ForEach(user, id: \.id) { request in
//                        Image(request.imageName)
//                            .resizable()
//                            .frame(width: 50, height: 50)
//                            .clipShape(Circle())
//                            .overlay(Circle().stroke(universalAccentColor, lineWidth: 2))
//                    }
                }
            }
        }
    }
    
    var friendsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("friends")
                .font(.headline)
                .foregroundColor(universalAccentColor)
            ScrollView(.horizontal, showsIndicators: false) {
//                //TODO: figuring out how to display friends
                HStack(spacing: 12) {
//                    FriendRow(friend: user)
                }
            }
        }
    }
}
