//
//  ExpandedTagView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct ExpandedTagView: View {
    var friendTag: FriendTag
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(friendTag.displayName)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                EditButton()
            }
            
            ColorOptions()
            
            VStack(spacing: 10) {
                if let friends = friendTag.friends, !friends.isEmpty {
                    ForEach(friends) { friend in
                        FriendRow(friend: friend)
                            .padding(.horizontal)
                    }
                } else {
                    Text("No friends added yet.")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: friendTag.colorHexCode).opacity(0.2))
        )
    }
}
