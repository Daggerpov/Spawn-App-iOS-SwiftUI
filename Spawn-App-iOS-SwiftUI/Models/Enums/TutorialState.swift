//
//  TutorialState.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 1/21/25.
//

import Foundation

/// Enum representing the current state of the first-time tutorial flow
enum TutorialState: Codable, Equatable {
	case notStarted
	case activityTypeSelection  // User needs to select an activity type
	case activityCreation(selectedActivityType: String)  // User has selected type, going through creation flow
	case completed  // Tutorial is finished

	var description: String {
		switch self {
		case .notStarted:
			return "Not Started"
		case .activityTypeSelection:
			return "Activity Type Selection"
		case .activityCreation(let type):
			return "Activity Creation (\(type))"
		case .completed:
			return "Completed"
		}
	}

	/// Check if the tutorial is currently active
	var isActive: Bool {
		switch self {
		case .notStarted, .completed:
			return false
		case .activityTypeSelection, .activityCreation:
			return true
		}
	}

	/// Check if we should show the tutorial overlay
	var shouldShowTutorialOverlay: Bool {
		switch self {
		case .activityTypeSelection:
			return true
		case .notStarted, .activityCreation, .completed:
			return false
		}
	}

	/// Check if navigation should be restricted
	var shouldRestrictNavigation: Bool {
		switch self {
		case .activityTypeSelection:
			return true
		case .notStarted, .activityCreation, .completed:
			return false
		}
	}
}
