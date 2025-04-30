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
		HStack {
			Image(systemName: "magnifyingglass")
				.font(.onestRegular(size: 18))
				.foregroundColor(.gray)
			
			TextField(searchPlaceholderText, text: $viewModel.searchText)
				.font(.onestRegular(size: 16))
				.foregroundColor(.black)
				.accentColor(.black)
		}
		.padding(.vertical, 12)
		.padding(.horizontal, 16)
		.background(
			RoundedRectangle(cornerRadius: 24)
				.fill(Color(UIColor.systemGray5))
		)
	}
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	@Previewable @StateObject var viewModel: SearchViewModel = SearchViewModel()
	SearchView(searchPlaceholderText: "Search for friends", viewModel: viewModel).environmentObject(appCache)
}
