//
//  BaseCacheService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-07.
//

import Combine
import Foundation

/// Protocol defining common cache service functionality
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
class BaseCacheService {
	// MARK: - Properties

	/// Background queue for disk operations
	let diskQueue = DispatchQueue(label: "com.spawn.cache.diskQueue", qos: .utility)

	/// Pending save task for debouncing
	var pendingSaveTask: DispatchWorkItem?

	/// Debounce interval for saving to disk
	let saveDebounceInterval: TimeInterval = 1.0

	/// User-specific cache timestamps
	var lastChecked: [UUID: [String: Date]] = [:]

	// MARK: - Initialization

	init() {
		// Set up a timer to periodically save to disk (debounced)
		Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
			self?.saveToDisk()
		}
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

			await MainActor.run {
				updateCache(fetchedData)
			}
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

			await MainActor.run {
				updateCache(fetchedData)
			}
		} catch {
			print("Failed to refresh \(endpoint): \(error.localizedDescription)")
		}
	}

	// MARK: - Persistence Helpers

	/// Generic encode-save helper
	func saveToDefaults<T: Encodable>(_ data: T, key: String) {
		if let encoded = try? JSONEncoder().encode(data) {
			UserDefaults.standard.set(encoded, forKey: key)
		}
	}

	/// Generic decode-load helper
	func loadFromDefaults<T: Decodable>(key: String) -> T? {
		guard let data = UserDefaults.standard.data(forKey: key),
			let decoded = try? JSONDecoder().decode(T.self, from: data)
		else {
			return nil
		}
		return decoded
	}

	/// Debounced save that prevents excessive disk writes
	func debouncedSaveToDisk(saveAction: @escaping () -> Void) {
		// Cancel any pending save task
		pendingSaveTask?.cancel()

		// Create a new save task
		let task = DispatchWorkItem { [weak self] in
			self?.diskQueue.async {
				saveAction()
			}
		}

		// Store the task and schedule it
		pendingSaveTask = task
		diskQueue.asyncAfter(deadline: .now() + saveDebounceInterval, execute: task)
	}

	/// Template method for subclasses to implement actual save logic
	func saveToDisk() {
		// Subclasses should override this
	}
}
