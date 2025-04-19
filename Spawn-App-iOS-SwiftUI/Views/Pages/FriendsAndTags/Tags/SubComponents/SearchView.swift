//
//  SearchView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-11-19.
//

import SwiftUI

struct SearchView: View {
	@ObservedObject var viewModel: SearchViewModel
	var searchPlaceholderText: String

	init(searchPlaceholderText: String, viewModel: SearchViewModel) {
		self.searchPlaceholderText = searchPlaceholderText
		self.viewModel = viewModel
	}

	var body: some View {
		VStack {
			HStack {
				Image(systemName: "magnifyingglass")
					.font(.title3)
					.foregroundColor(universalAccentColor)
				TextField(searchPlaceholderText, text: $viewModel.searchText)
					.foregroundColor(universalAccentColor)
					.colorScheme(.light)
					.placeholderColor(
						color: universalAccentColor, text: searchPlaceholderText
					)
					.accentColor(universalAccentColor)
					.tint(universalAccentColor)
			}
			.padding(.vertical, 20)
			.padding(.horizontal, 15)
			.frame(height: 45)
			.overlay(
				RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
					.stroke(universalAccentColor, lineWidth: 2)
			)
			.background(
				RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
					.fill(universalBackgroundColor)
			)
		}
		.padding(.horizontal)
	}
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	@Previewable @StateObject var viewModel: SearchViewModel = SearchViewModel()
	SearchView(searchPlaceholderText: "asdf", viewModel: viewModel).environmentObject(appCache)
}
