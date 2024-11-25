//
//  FriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/24/24.
//

import SwiftUI

struct FriendsView: View {
    let user: User
    @State private var selectedTab: FriendTagToggle = .friends
    @State private var searchText: String = ""
    
    init(user: User) {
        self.user = user
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                header
                searchBar
                TagsView(user: user)
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
            BackButton()
            Spacer()
            Picker("", selection: $selectedTab) {
                Text("friends")
                    .tag(FriendTagToggle.friends)
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
    
    var searchBar: some View {
        HStack {
            TextField("search or add friends", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 10)
        }
        .frame(height: 40)
    }
}

// MARK: - Reusable Components

struct BackButton: View {
    var body: some View {
        Image(systemName: "arrow.left")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.black)
            .overlay(
                NavigationLink(destination: {
                    FeedView()
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }
            )
    }
}

struct AddTagButton: View {
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .frame(height: 50)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                )
        }
    }
}

struct EditButton: View {
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "pencil")
                .foregroundColor(.black)
        }
    }
}

struct FriendRow: View {
    var friend: User
    var action: () -> Void = {}
    
    var body: some View {
        HStack {
            if let profilePictureString = friend.profilePicture {
                Image(profilePictureString)
                    .ProfileImageModifier(imageType: .chatMessage)
            }
            Text(friend.username)
                .font(.subheadline)
            Spacer()
            Button(action: action) {
                Image(systemName: "xmark")
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal)
    }
}

struct TagRow: View {
    @EnvironmentObject var user: ObservableUser
    var tagName: String
    var color: Color
    var action: () -> Void = {}
    
    var body: some View {
        HStack {
            Text(tagName)
                .font(.subheadline)
            Spacer()
            HStack(spacing: -10) {
                ForEach(0..<2) { _ in
                    Circle()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray.opacity(0.2))
                }
                Button(action: action) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
                .fill(color)
        )
    }
}

#Preview {
    @Previewable @StateObject var observableUser: ObservableUser = ObservableUser(
        user: .danielLee
    )
    FriendsView(user: observableUser.user)
}
