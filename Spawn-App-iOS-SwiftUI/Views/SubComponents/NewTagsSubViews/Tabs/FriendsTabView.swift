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
			userId: user.id,
			apiService: MockAPIService.isMocking
			? MockAPIService(userId: user.id) : APIService())
	}

	var body: some View {
		VStack {
			SearchView(searchPlaceholderText: "search or add friends")
		}
		.onAppear {
			Task{
				await viewModel.fetchAllData()
			}
		}
	}
}
