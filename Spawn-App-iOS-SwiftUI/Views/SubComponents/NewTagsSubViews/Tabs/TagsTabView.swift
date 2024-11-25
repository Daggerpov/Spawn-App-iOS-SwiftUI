//
//  TagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct TagsTabView: View {
    let user: User
    
    var body: some View {
        VStack{
            tagSection
            Spacer()
            Spacer()
            Spacer()
            closeFriendsSection
            Spacer()
            otherTagsSection
        }
        .padding()
    }
}

extension TagsTabView {
    var tagSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("TAGS")
                .font(.headline)
            
            AddTagButton()
        }
    }
    
    var closeFriendsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Close Friends")
                    .font(.headline)
                Spacer()
                EditButton()
            }
            
            ColorOptions()
            
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
