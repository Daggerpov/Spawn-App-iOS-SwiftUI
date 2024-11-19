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
            //search bar
            searchView
            
            ScrollView {
                //list of tags
                VStack(alignment: .leading, spacing: 20) {
                    // Title and Time Information
                    ForEach(viewModel.friendTags) { friendTag in
                        HStack {
                            Text(friendTag.displayName)
                                .foregroundColor(.white)
                                .padding()
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white)
                                .padding()
                        }
                        .background(friendTag.color)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding(20)
                .background(universalAccentColor)
                .cornerRadius(universalRectangleCornerRadius)
            }
            
            //add tag button
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
            //            .padding(.horizontal) // Reduces padding on the bottom
            //            .padding(.top, 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: "#E7E7DD"))
                .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding()
    }
}

extension TagsListView {
    var searchView: some View {
        VStack{
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundColor(universalAccentColor)
                TextField("Search", text: $viewModel.searchText)
                    .foregroundColor(universalAccentColor)
                    .placeholderColor(universalAccentColor)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 15)
            .frame(height: 45)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(universalAccentColor, lineWidth: 2)
            )
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(universalBackgroundColor)
            )
        }
        .padding(.vertical, 20)
    }
}
