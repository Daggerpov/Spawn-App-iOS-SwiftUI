//
//  Location.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

class Location: Codable {
    // MARK: stub for now, but will make more robust later after implementing map
    var locationName: String
    

	init(locationName: String) {
		self.locationName = locationName
	}
}

extension Location {
    static let mockLocation = Location(locationName: "Gold's Gym")
}
