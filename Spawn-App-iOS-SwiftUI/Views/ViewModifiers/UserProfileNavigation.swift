//
//  UserProfileNavigation.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created for lazy navigation to user profiles
//  This prevents ProfileViewModel from being initialized until navigation actually occurs
//

import SwiftUI

/// A type-erased wrapper for any Nameable type that can be used with navigationDestination
/// This enables lazy navigation - the destination view is only created when navigation occurs
struct UserProfileNavigationValue: Hashable {
	let id: UUID
	let name: String?
	let profilePicture: String?
	let username: String?

	/// The original Nameable object, stored for creating the destination view
	/// Not used in Hashable conformance - we only hash by id
	private let _user: any Nameable

	var user: any Nameable { _user }

	init(_ user: any Nameable) {
		self.id = user.id
		self.name = user.name
		self.profilePicture = user.profilePicture
		self.username = user.username
		self._user = user
	}

	// MARK: - Hashable conformance (only uses id for equality)

	static func == (lhs: UserProfileNavigationValue, rhs: UserProfileNavigationValue) -> Bool {
		lhs.id == rhs.id
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

/// View modifier that adds the navigation destination handler for user profiles
/// Apply this modifier to any view that contains NavigationLink(value: UserProfileNavigationValue)
struct UserProfileNavigationDestination: ViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: UserProfileNavigationValue.self) { navigationValue in
				UserProfileView(user: navigationValue.user)
			}
	}
}

extension View {
	/// Adds a navigation destination handler for UserProfileNavigationValue
	/// This enables lazy navigation to user profiles - the ProfileViewModel is only
	/// created when the user actually navigates to the profile
	///
	/// Usage:
	/// ```swift
	/// NavigationStack {
	///     MyView()
	///         .userProfileNavigationDestination()
	/// }
	/// ```
	func userProfileNavigationDestination() -> some View {
		modifier(UserProfileNavigationDestination())
	}
}
