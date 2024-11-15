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
        .padding(.horizontal) // Reduces padding on the bottom
        .padding(.top, 200)
    }
}
