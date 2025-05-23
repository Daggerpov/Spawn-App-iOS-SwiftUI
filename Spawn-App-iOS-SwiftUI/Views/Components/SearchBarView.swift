//
//  SearchBarView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-06-18.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.onestRegular(size: 18))
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $searchText)
                .font(.onestRegular(size: 16))
                .foregroundColor(universalAccentColor)
                .colorScheme(.light)
                .onChange(of: searchText) { newValue in
                    isSearching = !newValue.isEmpty
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    isSearching = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            Rectangle()
                .foregroundColor(universalBackgroundColor)
                .frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(
                        cornerRadius: universalRectangleCornerRadius
                    )
                        .inset(by: 0.75)
                        .stroke(.gray)
                )
        )
        .foregroundColor(universalAccentColor)
        .colorScheme(.light)
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var searchText = ""
	@Previewable @State var isSearching = false
    
    return SearchBarView(
        searchText: $searchText,
        isSearching: $isSearching,
        placeholder: "Search for friends"
    )
    .padding()
}
