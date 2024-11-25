//
//  TagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct TagsView: View {
    let user: User
    
    var body: some View {
        tagSection
        closeFriendsSection
        Spacer()
        otherTagsSection
    }
}

extension TagsView {
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
                if let friends = user.friends, !(user.friends?.isEmpty ?? false) {
                    ForEach(friends) { friend in
                        FriendRow(friend: friend)
                    }
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
                    .fill(index == 4 ? Color.gray.opacity(0.2) : eventColors[index])
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
                    TagRow(tagName: "Tag Name", color: eventColors[index])
                }
            }
        }
    }
}
