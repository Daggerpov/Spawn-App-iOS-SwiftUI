//
//  ProfileViewModelCache.swift
//  Spawn-App-iOS-SwiftUI
//
//  Ensures exactly one ProfileViewModel per userId across the app.
//  Prevents duplicate VMs when viewing same profile from multiple entry points
//  (e.g. MyProfileView + UserProfileView for own profile, or revisiting a friend).
//

import SwiftUI

/// Cache ensuring one ProfileViewModel per userId.
/// Used by MyProfileView, UserProfileView, and any view needing profile data.
@MainActor
final class ProfileViewModelCache {
	static let shared = ProfileViewModelCache()

	private var cache: [UUID: ProfileViewModel] = [:]
	private let maxCachedProfiles = 20

	private init() {}

	/// Returns the ProfileViewModel for the given userId. Creates and caches if needed.
	func viewModel(for userId: UUID) -> ProfileViewModel {
		if let existing = cache[userId] {
			return existing
		}
		let vm = ProfileViewModel(userId: userId)
		cache[userId] = vm
		evictIfNeeded()
		return vm
	}

	/// Evicts entries when cache exceeds max size. Keeps current user's VM.
	private func evictIfNeeded() {
		let currentUserId = UserAuthViewModel.shared.spawnUser?.id
		while cache.count > maxCachedProfiles, let keyToRemove = cache.keys.first(where: { $0 != currentUserId }) {
			cache.removeValue(forKey: keyToRemove)
		}
	}

	/// Call on logout to clear cached view models.
	func clear() {
		cache.removeAll()
	}
}
