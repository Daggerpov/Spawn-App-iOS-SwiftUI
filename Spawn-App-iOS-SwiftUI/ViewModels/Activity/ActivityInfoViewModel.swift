//
//  ActivityInfoViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import Foundation
import SwiftUI

class ActivityInfoViewModel: ObservableObject {
    @ObservedObject var activity: FullFeedActivityDTO
    @ObservedObject var locationManager: LocationManager

	init(activity: FullFeedActivityDTO, locationManager: LocationManager) {
        self.activity = activity
        self.locationManager = locationManager
	}
    
    func getDisplayString(activityInfoType: ActivityInfoType) -> String {
        switch activityInfoType {
            case .title:
                return activity.title ?? "\(activity.creatorUser.name ?? activity.creatorUser.username ?? "User")'s activity"
            case .location:
                return activity.location?.name ?? "No Location"
            case .time:
                return FormatterService.shared.formatActivityTime(activity: activity)
            case .distance:
                // Calculate distance dynamically using user location
                let calculatedDistance = FormatterService.shared.distanceString(
                    from: locationManager.userLocation,
                    to: activity.location
                )
                return calculatedDistance
            
        }
    }
    
    // Add method to update activity reference
    func updateActivity(_ newActivity: FullFeedActivityDTO) {
        self.activity = newActivity
        objectWillChange.send()
    }
}
