//
//  Nameable.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-03-01.
//

import Foundation

protocol Nameable {
    var id: UUID {get}
    var name: String? { get }
    var profilePicture: String? { get }
    var username: String? { get }
}
