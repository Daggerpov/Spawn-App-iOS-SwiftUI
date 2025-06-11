//
//  EventInfoViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import Foundation

class ActivityInfoViewModel: ObservableObject {
    private var locationDisplayString: String
    private var distanceDisplayString: String?
    private var timeDisplayString: String
    var activity: FullFeedEventDTO

	init(activity: FullFeedEventDTO) {
        self.activity = activity
        locationDisplayString = activity.location?.name ?? "No Location"
        timeDisplayString = FormatterService.shared.formatEventTime(event: activity)
	}
    
    func getDisplayString(activityInfoType: ActivityInfoType) -> String {
        switch activityInfoType {
            case .location:
                return locationDisplayString
            case .time:
                return timeDisplayString
            case .distance:
                guard let distanceDisplayString = self.distanceDisplayString else {
                    self.distanceDisplayString = FormatterService.shared.distanceString()
                    return self.distanceDisplayString!
                }
                return distanceDisplayString
            
        }
    }
    
    
}
