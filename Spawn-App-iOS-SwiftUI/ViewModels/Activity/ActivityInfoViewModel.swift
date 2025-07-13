//
//  ActivityInfoViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import Foundation
import SwiftUI

class ActivityInfoViewModel: ObservableObject {
    private var locationDisplayString: String
    private var distanceDisplayString: String?
    private var timeDisplayString: String
    @ObservedObject var activity: FullFeedActivityDTO
    @ObservedObject var locationManager: LocationManager

	init(activity: FullFeedActivityDTO, locationManager: LocationManager) {
        self.activity = activity
        self.locationManager = locationManager
        locationDisplayString = activity.location?.name ?? "No Location"
        timeDisplayString = FormatterService.shared.formatActivityTime(activity: activity)
	}
    
    func getDisplayString(activityInfoType: ActivityInfoType) -> String {
        switch activityInfoType {
            case .location:
                return locationDisplayString
            case .time:
                return timeDisplayString
            case .distance:
                // Calculate distance dynamically using user location
                let calculatedDistance = FormatterService.shared.distanceString(
                    from: locationManager.userLocation,
                    to: activity.location
                )
                return calculatedDistance
            
        }
    }
    
    
}
