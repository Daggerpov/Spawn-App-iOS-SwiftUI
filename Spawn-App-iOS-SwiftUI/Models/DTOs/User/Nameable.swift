//
//  Nameable.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-03-01.
//

import Foundation

/// Protocol for entities that can be named and displayed
/// Sendable since all properties are value types
protocol Nameable: Sendable {
	var id: UUID { get }
	var name: String? { get }
	var profilePicture: String? { get }
	var username: String? { get }
}
