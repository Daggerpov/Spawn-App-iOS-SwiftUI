//
//  FriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/24/24.
//

import SwiftUI

struct FriendsView: View {
    let user: User
	let source: BackButtonSourcePageType

    @State private var selectedTab: FriendTagToggle = .friends
    
	init(user: User, source: BackButtonSourcePageType) {
        self.user = user
		self.source = source
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                header
                if selectedTab == .friends {
                    FriendsTabView(user: user)
                } else {
                    TagsTabView(user: user)
                }
                requestsSection
                recommendedFriendsSection
                friendsSection
            }
            .padding()
            .background(universalBackgroundColor)
            .navigationBarHidden(true)
        }
    }
}

private extension FriendsView {
    var header: some View {
        HStack {
			BackButton(source: source)
            Spacer()
            Picker("", selection: $selectedTab) {
                Text("friends")
                    .tag(FriendTagToggle.friends)
                //TODO: change color of text to universalAccentColorHexCode when selected and universalBackgroundColor when not
                Text("tags")
                    .tag(FriendTagToggle.tags)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 150, height: 40)
            .background(
                RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
                    .fill(universalAccentColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
                    .stroke(universalBackgroundColor, lineWidth: 1)
            )
            .cornerRadius(universalRectangleCornerRadius)
            Spacer()
        }
        .padding(.horizontal)
    }
    
    var requestsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("requests")
                .font(.headline)
                .foregroundColor(.black)
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
    
    var recommendedFriendsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("recommended friends")
                .font(.headline)
                .foregroundColor(.black)
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
                .foregroundColor(.black)
            ScrollView(.horizontal, showsIndicators: false) {
//                //TODO: figuring out how to display friends
                HStack(spacing: 12) {
//                    FriendRow(friend: user)
                }
            }
        }
    }
    

}

@available(iOS 17.0, *)
#Preview
{
	@Previewable @StateObject var observableUser: ObservableUser = ObservableUser(
		user: .danielLee
	)
	FriendsView(user: observableUser.user, source: .feed)
}
