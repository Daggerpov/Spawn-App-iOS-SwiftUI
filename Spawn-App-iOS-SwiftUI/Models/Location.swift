//
//  Location.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel on 11/6/24.
//

struct Location: Codable {
    // MARK: stub for now, but will make more robust later after implementing map
    var locationName: String
}

extension Location {
    static let mockLocation = Location(locationName: "Gold's Gym")
}
