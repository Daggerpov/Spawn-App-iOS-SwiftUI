//
//  FriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/24/24.
//

import SwiftUI

struct FriendsView: View {
    @State private var selectedTab: FriendTagToggle = .friends
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                header
                searchBar
                tagSection
                closeFriendsSection
                Spacer()
                otherTagsSection
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
                Text("friends").tag(FriendTagToggle.friends)
                    .cornerRadius(universalRectangleCornerRadius)
                    .padding(.horizontal)
                    .foregroundColor(selectedTab == .friends ? universalAccentColor : universalBackgroundColor)
                    .background(
                        selectedTab == .friends ? universalBackgroundColor : universalAccentColor)
                Text("tags").tag(FriendTagToggle.tags)
                    .cornerRadius(universalRectangleCornerRadius)
                    .padding()
                    .foregroundColor(selectedTab == .tags ? universalAccentColor : universalBackgroundColor)
                    .background(
                        selectedTab == .tags ? universalBackgroundColor : universalAccentColor)
            }
            .background(universalAccentColor)
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 150)
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
    
    var tagSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("TAGS")
                .font(.headline)
            
            AddTagButton()
        }
        .padding(.top)
    }
    
    var closeFriendsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Close Friends")
                    .font(.headline)
                Spacer()
                EditButton()
            }
            
            colorOptions
            
            VStack(spacing: 10) {
                ForEach(["ethhansen", "gingy05", "username"], id: \.self) { friend in
                    FriendRow(name: friend)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.2)))
    }
    
    var colorOptions: some View {
        HStack(spacing: 15) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index == 4 ? Color.gray.opacity(0.2) : randomColor(index))
                    .frame(width: 30, height: 30)
                    .overlay(
                        index == 4
                        ? Image(systemName: "plus").foregroundColor(.black)
                        : nil
                    )
            }
        }
    }
    
    var otherTagsSection: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(0..<3) { index in
                    TagRow(tagName: "Tag Name", color: randomColor(index))
                }
            }
        }
    }
}

private extension FriendsView {
    func randomColor(_ index: Int) -> Color {
        let colors: [Color] = [.purple, .green, .red, .blue, .gray]
        return colors[index % colors.count]
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
    var name: String
    var action: () -> Void = {}
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: 40, height: 40)
                .foregroundColor(.gray.opacity(0.2))
            Text(name)
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
        .background(RoundedRectangle(cornerRadius: 12).fill(color))
    }
}

// MARK: - Preview

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
    }
}
