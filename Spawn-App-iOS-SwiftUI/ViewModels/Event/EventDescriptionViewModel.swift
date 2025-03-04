//
//  EventDescriptionViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation

class EventDescriptionViewModel: ObservableObject {
	@Published var users: [UserDTO]?
	var event: FullFeedEventDTO

	init(event: FullFeedEventDTO, users: [UserDTO]? = []) {
		self.event = event
		self.users = users
	}
}
