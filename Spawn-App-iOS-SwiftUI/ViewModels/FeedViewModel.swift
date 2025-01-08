//
//  FeedViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation

class FeedViewModel: ObservableObject {
    @Published var events: [Event] = []

	var apiService: IAPIService
	var user: User

	init(apiService: IAPIService, user: User) {
		self.apiService = apiService
		self.user = user
    }

	func fetchEventsForUser() async -> Void {
		if let url: URL = URL(string: APIService.baseURL + "events/user/\(user.id)") {
			do {
				events = try await self.apiService.fetchData(from: url)
			} catch {
				events = []
			}
		}
	}
}
