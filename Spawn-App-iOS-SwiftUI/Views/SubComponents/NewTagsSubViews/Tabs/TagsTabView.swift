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
            // TODO: change this event color logic later
            let numBum: Int = eventColors.count + 2
            ForEach(0..<(numBum)) { index in
                if index == 4 {
                    Circle()
                        .stroke(
                            Color.white,
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: [5, 3] // Length of dash and gap
                            )
                        )
                        .fill(index == 4 ? Color.gray.opacity(0.2) : eventColors[index])
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "plus").foregroundColor(.white)
                        )
                } else {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .fill(index == 4 ? Color.gray.opacity(0.2) : eventColors[index])
                        .frame(width: 30, height: 30)
                }
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
