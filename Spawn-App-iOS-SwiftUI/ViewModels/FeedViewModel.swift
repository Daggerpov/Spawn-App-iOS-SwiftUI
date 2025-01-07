//
//  FeedViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation

class FeedViewModel: ObservableObject {
    @Published var events: [Event]

	var apiService: IAPIService

	init(apiService: IAPIService, user: User) {
		self.events = fetchEventsForUser(user: user)
    }

	func fetchEventsForUser(user: User) -> [Event] {
		if let url: URL = URL(string: APIService.baseURL + "events/user/\(user.id)") {
			return apiService
				.fetchData(from: url)
		}
	}
}
