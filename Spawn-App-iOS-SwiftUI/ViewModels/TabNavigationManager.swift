//
//  TabNavigationManager.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created for managing tab navigation and pop-to-root functionality
//

import SwiftUI

/// Manages navigation state for each tab and handles pop-to-root when tabs are reselected
@MainActor
@Observable
final class TabNavigationManager {
	static let shared = TabNavigationManager()

	// Navigation reset triggers for each tab
	// Changing these IDs causes the NavigationStack to reset, popping to root
	var friendsNavigationId = UUID()
	var profileNavigationId = UUID()
	var homeNavigationId = UUID()

	private init() {}

	/// Triggers a reset of the navigation stack for the specified tab, popping to root
	/// Works by changing the NavigationStack's id, which causes SwiftUI to recreate it
	func popToRoot(for tab: Tabs) {
		switch tab {
		case .friends:
			friendsNavigationId = UUID()
		case .profile:
			profileNavigationId = UUID()
		case .home:
			homeNavigationId = UUID()
		case .map, .activities:
			// These tabs don't use NavigationStack or don't need pop-to-root
			break
		}
	}
}
