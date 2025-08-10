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
                let rawName = activity.location?.name ?? "No Location"
                // Split by commas; if there are 2+ components, join the first two to preserve street number and name
                let parts = rawName.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                let streetOnly: String = {
                    if parts.count >= 2 {
                        return parts[0] + " " + parts[1]
                    } else if let first = parts.first {
                        return String(first)
                    } else {
                        return rawName
                    }
                }()
                // Remove any stray commas and collapse whitespace
                let withoutCommas = streetOnly.replacingOccurrences(of: ",", with: " ")
                let collapsedWhitespace = withoutCommas
                    .components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                return collapsedWhitespace.trimmingCharacters(in: .whitespacesAndNewlines)
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
