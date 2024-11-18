//
//  TagsListView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct TagsListView: View {
    @ObservedObject var viewModel: TagsListViewModel
    
    init(appUser: AppUser) {
        self.viewModel = TagsListViewModel(appUser: appUser)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title and Time Information
                ForEach(viewModel.friendTags) { friendTag in
                    Text(friendTag.displayName)
                }
            }
            .padding(20)
            .background(universalAccentColor)
            .cornerRadius(universalRectangleCornerRadius)
        }
        Button(action: {
            // Action for adding a new tag
        }) {
            HStack {
                Image(systemName: "plus")
                    .font(.title)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundColor(.gray)
            )
        }
        .padding(.horizontal)
        .padding(.horizontal) // Reduces padding on the bottom
        .padding(.top, 200)
    }
}
