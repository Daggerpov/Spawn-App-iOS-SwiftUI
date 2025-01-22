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
        recommendedFriendsSection
        .onAppear {
            Task{
                await viewModel.fetchAllData()
            }
        }
        
    }
    
//    var requestsSection: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("requests")
//                .font(.headline)
//                .foregroundColor(universalAccentColor)
//            ScrollView(.horizontal, showsIndicators: false) {
////                //TODO: figuring out how to display the requests as circles below the 'requests' text
//                VStack(spacing: 12) {
////                    ForEach(user, id: \.id) { request in
////                        Image(request.imageName)
////                            .resizable()
////                            .frame(width: 50, height: 50)
////                            .clipShape(Circle())
////                            .overlay(Circle().stroke(universalAccentColor, lineWidth: 2))
////                    }
//                }
//            }
//        }
//    }
    
    //TODO#1: implement fetchIncomingFriendRequests() from FriendsTabViewModel
    var requestsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("requests")
                .font(.headline)
                .foregroundColor(universalAccentColor)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        VStack {
                            Image("profile\(index + 1)")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(universalAccentColor, lineWidth: 2)
                                )
                                .padding(.horizontal, 1)
                        }
                    }
                }
                .padding(.vertical, 2)  // Adjust padding for alignment
            }
        }
        .padding(.horizontal, 16)
    }
    
    //TODO: maybe a component for both recommended friends and friends?
    
//    var recommendedFriendsSection: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("recommended friends")
//                .font(.headline)
//                .foregroundColor(universalAccentColor)
//            ScrollView(.horizontal, showsIndicators: false) {
////                //TODO: figuring out how to display recommended friends
//                HStack(spacing: 12) {
////                    ForEach(user, id: \.id) { request in
////                        Image(request.imageName)
////                            .resizable()
////                            .frame(width: 50, height: 50)
////                            .clipShape(Circle())
////                            .overlay(Circle().stroke(universalAccentColor, lineWidth: 2))
////                    }
//                }
//            }
//        }
//        .padding(.horizontal, 16)
//    }
    
    //TODO#1: refine this scetion to show the greenbackground around each friend
    //TODO#2: implement fetchRecommendedFriends() from FriendsTabViewModel
    var recommendedFriendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("recommended friends")
                .font(.headline)
                .foregroundColor(universalAccentColor)

            VStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { index in
                    HStack {
                            Image("profile\(index + 1)")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(universalAccentColor, lineWidth: 2)
                                )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(index == 0 ? "★ jcrisologo" : "★ username")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)

                            Text(index == 0 ? "Jerimy Crisologo" : "full name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black)
                        }
                        .padding(.leading, 8)

                        Spacer()

                        Button(action: {
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)

                                Image(systemName: "person.badge.plus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(universalAccentColor)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .shadow(radius: 4)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .foregroundColor(universalAccentColor)
                    .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal, 16)
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
        .padding(.horizontal, 16)
    }

}
