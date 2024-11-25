//
//  SearchView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-11-19.
//

import SwiftUI

struct SearchView: View {
	@StateObject var viewModel: SearchViewModel = SearchViewModel()
    var searchPlaceholderText: String

	var body: some View {
		VStack{
			HStack {
				Image(systemName: "magnifyingglass")
					.font(.title3)
					.foregroundColor(universalAccentColor)
				TextField(searchPlaceholderText, text: $viewModel.searchText)
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
		.padding(.horizontal)
	}
}
