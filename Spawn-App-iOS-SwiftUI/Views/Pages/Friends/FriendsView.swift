//
//  FriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-24.
//

import SwiftUI

struct FriendsView: View {
    let user: BaseUserDTO
    @StateObject private var viewModel: FriendsTabViewModel

    init(user: BaseUserDTO) {
        self.user = user
        let vm = FriendsTabViewModel(
            userId: user.id,
            apiService: MockAPIService.isMocking
                ? MockAPIService(userId: user.id) : APIService())
        self._viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        FriendRequestNavButtonView
                        Spacer()
                    }
                    .padding(.horizontal)

                    FriendsTabView(user: user)
                }
                .padding()
                .background(universalBackgroundColor)
                .navigationBarHidden(true)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchIncomingFriendRequests()
            }
        }
    }
}

struct BaseFriendNavButtonView: View {
    var iconImageName: String
    var topText: String
    var bottomText: String

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text(topText)
                        .onestSubheadline()
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.bottom, 6)
                    Spacer()
                }
                HStack {
                    Text(bottomText)
                        .onestSmallText()
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: true, vertical: false)
                        .lineLimit(1)
                    Spacer()
                }
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.leading, 8)
            .padding(.vertical, 8)
            Image(iconImageName)
                .resizable()
                .frame(width: 50, height: 50)
        }
        .background(universalSecondaryColor)
        .cornerRadius(12)
    }
}

extension FriendsView {
    var FriendRequestNavButtonView: some View {
        NavigationLink(destination: {
            FriendRequestsView(userId: user.id)
        }) {
            HStack {
                HStack(spacing: 8) {
                    Text("Friend Requests")
                        .font(Font.custom("Onest", size: 17).weight(.semibold))
                        .foregroundColor(.white)
                    
                    // Only show red indicator if there are friend requests
                    if viewModel.incomingFriendRequests.count > 0 {
                        VStack(spacing: 10) {
                            Text("\(viewModel.incomingFriendRequests.count)")
                                .font(Font.custom("Onest", size: 12).weight(.semibold))
                                .lineSpacing(14.40)
                                .foregroundColor(.white)
                        }
                        .padding(EdgeInsets(top: 7, leading: 11, bottom: 7, trailing: 11))
                        .frame(width: 20, height: 20)
                        .background(Color(red: 1, green: 0.45, blue: 0.44))
                        .cornerRadius(16)
                    }
                }
                
                Spacer()
                
                Text("View All >")
                    .font(Font.custom("Onest", size: 16).weight(.semibold))
                    .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.80))
            }
            .padding(16)
            .background(Color(red: 0.33, green: 0.42, blue: 0.93))
            .cornerRadius(12)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    FriendsView(user: .danielAgapov).environmentObject(appCache)
}
