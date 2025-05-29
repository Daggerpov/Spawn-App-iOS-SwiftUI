//
//  ActivityInfoViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import Foundation

class ActivityInfoViewModel: ObservableObject {
	@Published var activityInfoDisplayString: String
	@Published var imageSystemName: String

	init(activity: FullFeedActivityDTO, activityInfoType: ActivityInfoType) {
		switch activityInfoType {
		case .location:
			imageSystemName = "map"
			self.activityInfoDisplayString = activity.location?.name ?? "No Location"
		case .time:
			imageSystemName = "clock"
			self.activityInfoDisplayString = FormatterService.shared
				.formatActivityTime(activity: activity)
		}
	}
} 