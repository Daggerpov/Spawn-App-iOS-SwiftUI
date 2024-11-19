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
        VStack{
			// search bar
			SearchView()

            ScrollView {
                //list of tags
                VStack(alignment: .leading, spacing: 20) {
                    // Title and Time Information
                    ForEach(viewModel.friendTags) { friendTag in
                        HStack {
                            Text(friendTag.displayName)
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
						.padding()
						.padding(.vertical, 10)
						.foregroundColor(.white)
                        .background(friendTag.color)
						.cornerRadius(universalRectangleCornerRadius)
                        .padding(.horizontal)
                    }
                }
            }
            
            //add tag button
            Button(action: {
                // Action for adding a new tag
            }) {
                HStack {
                    Image(systemName: "plus")
                        .font(.title)
						.foregroundColor(universalAccentColor)
						.padding(.vertical, 24)
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [11]))
                        .foregroundColor(universalAccentColor)
                )
				.padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(universalBackgroundColor)
                .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
        )
		.padding(.top, 125)
		.padding(.bottom, 150)
		.padding(.horizontal, 24)
    }
}
