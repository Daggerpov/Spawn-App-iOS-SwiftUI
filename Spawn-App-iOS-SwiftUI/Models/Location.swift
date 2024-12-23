//
//  Location.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

class Location: Identifiable, Codable {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double

    init(id: UUID, name: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
	}
}

extension Location {
    static let goldsGym = Location(id: UUID(), name: "Gold's Gym", latitude: 49.26629781435629, longitude: -123.24236920903301)
    static let amsNest = Location(id: UUID(), name: "AMS Nest", latitude: 49.26672332535917, longitude: -123.2500705312989)
    static let ikbLibrary = Location(id: UUID(), name: "IKB Library", latitude: 49.26764036247616, longitude: -123.25272383355049)
}
