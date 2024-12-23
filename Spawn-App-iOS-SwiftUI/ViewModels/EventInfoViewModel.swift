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

    init(event: Event, eventInfoType: EventInfoType) {
		switch eventInfoType {
			case .location:
				imageSystemName = "map"
				if let eventLocation = event.location?.name {
					self.eventInfoDisplayString = eventLocation
				} else {
					// nil event location (should be error?)
					self.eventInfoDisplayString = "No Location"
				}
			case .time:
				imageSystemName = "clock"
				self.eventInfoDisplayString = FormatterService.shared.formatEventTime(event: event)
		}
    }
}
