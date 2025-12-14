//
//  ProfilePictureCache.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2025-01-03.
//

import Foundation
import SwiftUI
import UIKit

/// A singleton service that manages profile picture downloading with memory and disk caching
/// Refactored to use Swift Concurrency (actors) for automatic thread-safety
actor ProfilePictureCache {
	static let shared = ProfilePictureCache()

	// MARK: - Properties
	private let fileManager = FileManager.default
	private let cacheDirectory: URL

	// In-memory cache for recently accessed images
	private var memoryCache: [UUID: UIImage] = [:]

	// Metadata about cached images
	private var cacheMetadata: [UUID: CacheMetadata] = [:]
	private let metadataKey = "ProfilePictureCacheMetadata"

	// Tracks in-flight download tasks to prevent duplicate downloads
	private var inFlightTasks: [UUID: Task<UIImage?, Error>] = [:]

	// MARK: - Initialization
	private init() {
		// Create cache directory
		let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
		cacheDirectory = cachesDirectory.appendingPathComponent("ProfilePictures")

		// Create directory if it doesn't exist
		try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

		// Load metadata
		loadMetadata()

		print("   Cache directory: \(cacheDirectory.path)")
	}

	// MARK: - Public Methods

	/// Download an image from a URL for a user ID with caching
	func downloadAndCacheImage(from urlString: String, for userId: UUID, forceRefresh: Bool = false) async -> UIImage? {
		print("🌐 [DOWNLOAD] downloadAndCacheImage for user \(userId)")
		print("   URL: \(urlString)")
		print("   Force refresh: \(forceRefresh)")

		guard let url = URL(string: urlString) else {
			print("❌ [DOWNLOAD] Invalid URL: \(urlString)")
			return nil
		}

		// Check cache first (unless force refresh)
		if !forceRefresh {
			if let cached = try? loadFromDisk(userId: userId) ?? memoryCache[userId] {
				return cached
			}
		}

		// Deduplication: if already downloading, wait for that task
		if let task = inFlightTasks[userId] {
			print("⏳ [CACHE] Deduplicating download for user \(userId)")
			return try? await task.value
		}

		// Create new download task
		let task = Task<UIImage?, Error> {
			try? await self.performDownloadAndCache(url: url, userId: userId)
		}

		inFlightTasks[userId] = task

		defer {
			inFlightTasks[userId] = nil
		}

		return try? await task.value
	}

	/// Get an image with automatic download and caching
	/// This is the main entry point for UI components
	func getCachedImageWithRefresh(for userId: UUID, from urlString: String?, maxAge: TimeInterval = 24 * 60 * 60) async
		-> UIImage?
	{
		guard let urlString = urlString else {
			print("❌ [DOWNLOAD] No URL provided for user \(userId)")
			return nil
		}

		// Check if cached image exists
		let cachedImage = try? loadFromDisk(userId: userId) ?? memoryCache[userId]

		if let image = cachedImage {
			// Check if it's stale
			let isStale = isProfilePictureStale(for: userId, maxAge: maxAge)

			if !isStale {
				return image
			} else {
				// Return stale image immediately, refresh in background
				print("⚠️ [CACHE] Returning stale cached image for user \(userId), refreshing in background")
				Task.detached(priority: .background) {
					_ = await self.downloadAndCacheImage(from: urlString, for: userId, forceRefresh: true)
				}
				return image
			}
		}

		// No cached image - download
		print("❌ [CACHE] No cached image, downloading for user \(userId)")
		return await downloadAndCacheImage(from: urlString, for: userId, forceRefresh: false)
	}

	/// Download profile pictures for multiple users (in parallel using TaskGroup)
	func refreshStaleProfilePictures(for users: [(userId: UUID, profilePictureUrl: String?)]) async {
		await withTaskGroup(of: Void.self) { group in
			for user in users {
				guard let profilePictureUrl = user.profilePictureUrl else { continue }

				if isProfilePictureStale(for: user.userId) {
					group.addTask {
						_ = await self.downloadAndCacheImage(
							from: profilePictureUrl, for: user.userId, forceRefresh: true)
					}
				}
			}
		}
	}

	/// Force refresh a profile picture from the backend
	func refreshProfilePicture(for userId: UUID, urlString: String) async -> UIImage? {
		return await downloadAndCacheImage(from: urlString, for: userId, forceRefresh: true)
	}

	/// Check if a cached profile picture is stale
	func isProfilePictureStale(for userId: UUID, maxAge: TimeInterval = 24 * 60 * 60) -> Bool {
		guard let metadata = cacheMetadata[userId] else {
			return true
		}

		let ageInSeconds = Date().timeIntervalSince(metadata.cachedAt)
		return ageInSeconds > maxAge
	}

	/// Remove cached image for a user ID
	func removeCachedImage(for userId: UUID) {
		// Remove from memory cache
		memoryCache.removeValue(forKey: userId)

		// Remove from disk
		let fileURL = fileURL(for: userId)
		try? fileManager.removeItem(at: fileURL)

		// Remove metadata
		cacheMetadata.removeValue(forKey: userId)
		saveMetadata()

		print("🗑️ [CACHE] Removed cached image for user \(userId)")
	}

	/// Clear all cached images
	func clearAllCache() {
		// Clear memory cache
		memoryCache.removeAll()

		// Clear disk cache
		if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: nil) {
			for case let fileURL as URL in enumerator {
				try? fileManager.removeItem(at: fileURL)
			}
		}

		// Clear metadata
		cacheMetadata.removeAll()
		saveMetadata()

		print("🗑️ [CACHE] Cleared all cached images")
	}

	// MARK: - Private Methods - Download & Caching

	/// Internal method that performs the actual download and caching
	private func performDownloadAndCache(url: URL, userId: UUID) async throws -> UIImage {
		let (data, response) = try await URLSession.shared.data(from: url)

		if let httpResponse = response as? HTTPURLResponse {

			if httpResponse.statusCode != 200 {
				print("❌ [DOWNLOAD] HTTP error \(httpResponse.statusCode) for user \(userId)")
				throw URLError(.badServerResponse)
			}
		}

		guard let image = UIImage(data: data) else {
			print("❌ [DOWNLOAD] Failed to create image from data for user \(userId)")
			throw URLError(.cannotDecodeContentData)
		}

		// Store in memory cache
		memoryCache[userId] = image

		// Store on disk
		await saveToDisk(image, for: userId)

		return image
	}

	// MARK: - Private Methods - Disk Operations

	private func saveToDisk(_ image: UIImage, for userId: UUID) async {
		let key = userId.uuidString
		guard let imageData = image.jpegData(compressionQuality: 0.8) else {
			print("❌ [CACHE] Failed to convert image to JPEG data for key \(key)")
			return
		}

		let fileURL = cacheDirectory.appendingPathComponent("\(key).jpg")

		do {
			try imageData.write(to: fileURL)

			// Update metadata
			let metadata = CacheMetadata(
				cachedAt: Date(),
				lastAccessed: Date(),
				fileSize: Int64(imageData.count)
			)
			cacheMetadata[userId] = metadata
			saveMetadata()

		} catch {
			print("❌ [CACHE] Failed to save image to disk for key \(key): \(error.localizedDescription)")
		}
	}

	private func loadFromDisk(userId: UUID) throws -> UIImage? {
		let key = userId.uuidString
		let fileURL = cacheDirectory.appendingPathComponent("\(key).jpg")

		guard fileManager.fileExists(atPath: fileURL.path) else {
			return nil
		}

		let imageData = try Data(contentsOf: fileURL)
		let image = UIImage(data: imageData)

		if let image = image {
			// Cache hit on disk - store in memory for next time
			memoryCache[userId] = image

			// Update metadata
			updateLastAccessed(for: userId)
			saveMetadata()
		}

		return image
	}

	private func fileURL(for userId: UUID) -> URL {
		let key = userId.uuidString
		return cacheDirectory.appendingPathComponent("\(key).jpg")
	}

	// MARK: - Private Methods - Metadata

	private func updateLastAccessed(for userId: UUID) {
		cacheMetadata[userId]?.lastAccessed = Date()
	}

	nonisolated private func loadMetadata() {
		guard let data = UserDefaults.standard.data(forKey: metadataKey),
			let metadata = try? JSONDecoder().decode([UUID: CacheMetadata].self, from: data)
		else {
			print("ℹ️ [CACHE] No existing metadata found")
			return
		}
		// Schedule async initialization of metadata
		Task { @MainActor [weak self] in
			guard let self = self else { return }
			await self.setLoadedMetadata(metadata)
		}
	}

	private func setLoadedMetadata(_ metadata: [UUID: CacheMetadata]) {
		cacheMetadata = metadata
	}

	private func saveMetadata() {
		guard let data = try? JSONEncoder().encode(cacheMetadata) else {
			print("❌ [CACHE] Failed to encode metadata")
			return
		}
		UserDefaults.standard.set(data, forKey: metadataKey)
	}
}

// MARK: - Supporting Types

private struct CacheMetadata: Codable {
	let cachedAt: Date
	var lastAccessed: Date
	let fileSize: Int64
}
