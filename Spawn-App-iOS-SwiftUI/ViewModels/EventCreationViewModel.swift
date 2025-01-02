//
//  EventCreationViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import Foundation

class EventCreationViewModel: ObservableObject {
	@Published var event: Event

	init(creatingUser: User) {
		self.event = Event(id: UUID(), title: "", creator: creatingUser)
	}

}
