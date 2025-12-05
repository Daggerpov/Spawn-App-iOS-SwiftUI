//
//  BaseCacheService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-07.
//

import Combine
import Foundation

/// Protocol defining common cache service functionality
/// MainActor isolated since all cache services manage UI-related state
@MainActor
protocol CacheService: AnyObject {
	/// Clear all cached data for this service
	func clearAllCaches()

	/// Clear cached data for a specific user
	func clearDataForUser(_ userId: UUID)

	/// Validate and refresh cache if needed
	func validateCache(userId: UUID, timestamps: [String: Date]) async

	/// Force refresh all data
	func forceRefreshAll() async

	/// Save data to disk
	func saveToDisk()
}

/// Base class providing shared functionality for cache services
@MainActor
class BaseCacheService {
	// MARK: - Properties

	/// Pending save task for debouncing
	/// nonisolated(unsafe) for deinit access
	private nonisolated(unsafe) var pendingSaveTask: Task<Void, Never>?

	/// Debounce interval for saving to disk
	let saveDebounceInterval: TimeInterval = 1.0

	/// User-specific cache timestamps
	var lastChecked: [UUID: [String: Date]] = [:]

	/// Timer for periodic save
	/// nonisolated(unsafe) for deinit access
	private nonisolated(unsafe) var periodicSaveTimer: Timer?

	// MARK: - Initialization

	init() {
		// Set up a timer to periodically save to disk (debounced)
		periodicSaveTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
			guard let self = self else { return }
			Task { @MainActor in
				self.saveToDisk()
			}
		}
	}

	deinit {
		periodicSaveTimer?.invalidate()
		pendingSaveTask?.cancel()
	}

	// MARK: - Timestamp Management

	/// Get cache timestamps for a specific user
	func getLastCheckedForUser(_ userId: UUID) -> [String: Date] {
		return lastChecked[userId] ?? [:]
	}

	/// Set cache timestamp for a specific user and cache type
	func setLastCheckedForUser(_ userId: UUID, cacheType: String, date: Date) {
		if lastChecked[userId] == nil {
			lastChecked[userId] = [:]
		}
		lastChecked[userId]![cacheType] = date
	}

	/// Clear cache timestamps for a specific user
	func clearLastCheckedForUser(_ userId: UUID) {
		lastChecked.removeValue(forKey: userId)
	}

	// MARK: - Generic Helpers

	/// No-op async function for conditional parallel execution
	func noop() async {
		// Does nothing - used for conditional async let statements
	}

	/// Generic refresh function to reduce code duplication
	func genericRefresh<T: Decodable>(
		endpoint: String,
		parameters: [String: String]? = nil,
		updateCache: @escaping ([T]) -> Void
	) async {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("Cannot refresh \(endpoint): No logged in user")
			return
		}

		guard UserAuthViewModel.shared.isLoggedIn else {
			print("Cannot refresh \(endpoint): User is not logged in")
			return
		}

		do {
			let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
			guard let url = URL(string: APIService.baseURL + endpoint) else { return }

			let fetchedData: [T] = try await apiService.fetchData(from: url, parameters: parameters)
			updateCache(fetchedData)
		} catch {
			print("Failed to refresh \(endpoint): \(error.localizedDescription)")
		}
	}

	/// Generic single item refresh function
	func genericSingleRefresh<T: Decodable>(
		endpoint: String,
		parameters: [String: String]? = nil,
		updateCache: @escaping (T) -> Void
	) async {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("Cannot refresh \(endpoint): No logged in user")
			return
		}

		guard UserAuthViewModel.shared.isLoggedIn else {
			print("Cannot refresh \(endpoint): User is not logged in")
			return
		}

		do {
			let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
			guard let url = URL(string: APIService.baseURL + endpoint) else { return }

			let fetchedData: T = try await apiService.fetchData(from: url, parameters: parameters)
			updateCache(fetchedData)
		} catch {
			print("Failed to refresh \(endpoint): \(error.localizedDescription)")
		}
	}

	// MARK: - Persistence Helpers

	/// Generic encode-save helper
	/// Nonisolated since UserDefaults is thread-safe and this doesn't access MainActor state
	nonisolated func saveToDefaults<T: Encodable>(_ data: T, key: String) {
		if let encoded = try? JSONEncoder().encode(data) {
			UserDefaults.standard.set(encoded, forKey: key)
		}
	}

	/// Generic decode-load helper
	/// Nonisolated since UserDefaults is thread-safe and this doesn't access MainActor state
	nonisolated func loadFromDefaults<T: Decodable>(key: String) -> T? {
		guard let data = UserDefaults.standard.data(forKey: key),
			let decoded = try? JSONDecoder().decode(T.self, from: data)
		else {
			return nil
		}
		return decoded
	}

	/// Debounced save that prevents excessive disk writes using Swift Concurrency
	func debouncedSaveToDisk(saveAction: @escaping @Sendable () -> Void) {
		// Cancel any pending save task
		pendingSaveTask?.cancel()

		// Create a new save task with debounce delay
		pendingSaveTask = Task { [weak self] in
			guard let self = self else { return }
			try? await Task.sleep(for: .seconds(self.saveDebounceInterval))

			// Check if task was cancelled during sleep
			guard !Task.isCancelled else { return }

			// Perform save action on a background thread
			await Task.detached(priority: .utility) {
				saveAction()
			}.value
		}
	}

	/// Template method for subclasses to implement actual save logic
	func saveToDisk() {
		// Subclasses should override this
	}
}
