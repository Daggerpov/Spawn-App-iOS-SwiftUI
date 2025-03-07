//
//  EventInfoViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import Foundation

class EventInfoViewModel: ObservableObject {
	@Published var eventInfoDisplayString: String
	@Published var imageSystemName: String

	init(event: FullFeedEventDTO, eventInfoType: EventInfoType) {
		switch eventInfoType {
		case .location:
			imageSystemName = "map"
			self.eventInfoDisplayString = event.location?.name ?? "No Location"
		case .time:
			imageSystemName = "clock"
			self.eventInfoDisplayString = FormatterService.shared
				.formatEventTime(event: event)
		}
	}
}
