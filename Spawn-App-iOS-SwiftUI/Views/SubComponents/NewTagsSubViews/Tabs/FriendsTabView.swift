//
//  FriendsTabView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct FriendsTabView: View {
	@ObservedObject var viewModel: FriendsTabViewModel
	let user: User

	init(user: User) {
		self.user = user
		self.viewModel = FriendsTabViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService() : APIService())
	}

	var body: some View {
		VStack {
			SearchView(searchPlaceholderText: "search or add friends")
		}
		.onAppear {
			viewModel.fetchAllData()
		}
	}
}
