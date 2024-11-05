//
//  Event.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel on 11/4/24.
//

import Foundation

struct Event: Identifiable, Codable {
    var id: UUID
    var title: String
    var startTime: String // TODO: change to proper time later
    var endTime: String // TODO: change to proper time later
    var location: String // TODO: change to proper location later
    var symbolName: String // TODO: maybe change later?
}
