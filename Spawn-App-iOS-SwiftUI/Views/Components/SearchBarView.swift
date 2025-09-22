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
    var autofocus: Bool = false
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.onestRegular(size: 18))
                .foregroundColor(universalAccentColor)
            
            TextField(placeholder, text: $searchText)
                .font(.onestRegular(size: 16))
                .foregroundColor(universalAccentColor)
                .focused($isTextFieldFocused)
                .onChange(of: searchText) { newValue in
                    isSearching = !newValue.isEmpty
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    isSearching = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(universalAccentColor)
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
                        cornerRadius: 15
                    )
                        .inset(by: 0.75)
                        .stroke(universalAccentColor)
                )
        )
        .onAppear {
            if autofocus {
                // Small delay to ensure the view is fully loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var searchText = ""
	@Previewable @State var isSearching = false
    
    return SearchBarView(
        searchText: $searchText,
        isSearching: $isSearching,
        placeholder: "Search for friends",
        autofocus: true
    )
    .padding()
}
