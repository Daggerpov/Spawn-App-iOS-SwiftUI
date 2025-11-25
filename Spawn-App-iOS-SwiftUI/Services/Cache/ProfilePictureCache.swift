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
class ProfilePictureCache: ObservableObject {
	static let shared = ProfilePictureCache()

	// MARK: - Properties
	private let fileManager = FileManager.default
	private let cacheDirectory: URL

	// In-memory cache for recently accessed images
	private let memoryCache: NSCache<NSString, UIImage>

	// Metadata about cached images
	private var cacheMetadata: [String: CacheMetadata] = [:]
	private let metadataKey = "ProfilePictureCacheMetadata"

	// MARK: - Initialization
	private init() {
		// Create cache directory
		let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
		cacheDirectory = cachesDirectory.appendingPathComponent("ProfilePictures")

		// Create directory if it doesn't exist
		try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

		// Initialize memory cache
		memoryCache = NSCache<NSString, UIImage>()
		memoryCache.countLimit = 100  // Cache up to 100 images in memory
		memoryCache.totalCostLimit = 50 * 1024 * 1024  // 50MB memory limit

		// Load metadata
		loadMetadata()

		print("✅ [CACHE] ProfilePictureCache initialized")
		print("   Cache directory: \(cacheDirectory.path)")
	}

	// MARK: - Public Methods

	/// Get a cached image for a user ID, or nil if not cached
	func getCachedImage(for userId: UUID) -> UIImage? {
		let key = userId.uuidString

		// Check memory cache first
		if let image = memoryCache.object(forKey: key as NSString) {
			print("✅ [CACHE] Memory cache HIT for user \(userId)")
			return image
		}

		// Check disk cache
		let fileURL = cacheDirectory.appendingPathComponent("\(key).jpg")

		guard fileManager.fileExists(atPath: fileURL.path),
			let imageData = try? Data(contentsOf: fileURL),
			let image = UIImage(data: imageData)
		else {
			print("❌ [CACHE] Cache MISS for user \(userId)")
			return nil
		}

		// Cache hit on disk - store in memory for next time
		print("✅ [CACHE] Disk cache HIT for user \(userId)")
		memoryCache.setObject(image, forKey: key as NSString)

		// Update metadata
		updateLastAccessed(for: key)
		saveMetadata()

		return image
	}

	/// Cache an image for a user ID
	private func cacheImage(_ image: UIImage, for userId: UUID) {
		let key = userId.uuidString

		// Store in memory cache
		memoryCache.setObject(image, forKey: key as NSString)
		print("✅ [CACHE] Stored in memory cache for user \(userId)")

		// Store on disk
		Task {
			await saveToDisk(image, for: key)
		}
	}

	/// Download an image from a URL for a user ID with caching
	func downloadAndCacheImage(from urlString: String, for userId: UUID, forceRefresh: Bool = false) async -> UIImage? {
		print("🌐 [DOWNLOAD] downloadAndCacheImage for user \(userId)")
		print("   URL: \(urlString)")
		print("   Force refresh: \(forceRefresh)")

		// Check cache first (unless force refresh)
		if !forceRefresh, let cachedImage = getCachedImage(for: userId) {
			print("✅ [CACHE] Returning cached image for user \(userId)")
			return cachedImage
		}

		guard let url = URL(string: urlString) else {
			print("❌ [DOWNLOAD] Invalid URL: \(urlString)")
			return nil
		}

		do {
			let (data, response) = try await URLSession.shared.data(from: url)

			if let httpResponse = response as? HTTPURLResponse {
				print("   HTTP Status: \(httpResponse.statusCode)")

				if httpResponse.statusCode != 200 {
					print("❌ [DOWNLOAD] HTTP error \(httpResponse.statusCode) for user \(userId)")
					return nil
				}
			}

			guard let image = UIImage(data: data) else {
				print("❌ [DOWNLOAD] Failed to create image from data for user \(userId)")
				return nil
			}

			print("✅ [DOWNLOAD] Successfully downloaded image for user \(userId)")

			// Cache the image
			cacheImage(image, for: userId)

			return image

		} catch {
			print("❌ [DOWNLOAD] Download failed for user \(userId): \(error.localizedDescription)")
			return nil
		}
	}

	/// Get an image with automatic download and caching
	/// This is the main entry point for UI components
	func getCachedImageWithRefresh(for userId: UUID, from urlString: String?, maxAge: TimeInterval = 24 * 60 * 60) async
		-> UIImage?
	{
		print("🔄 [CACHE] getCachedImageWithRefresh for user \(userId)")

		guard let urlString = urlString else {
			print("❌ [DOWNLOAD] No URL provided for user \(userId)")
			return nil
		}

		// Check if cached image exists
		if let cachedImage = getCachedImage(for: userId) {
			// Check if it's stale
			let isStale = isProfilePictureStale(for: userId, maxAge: maxAge)

			if !isStale {
				print("✅ [CACHE] Returning fresh cached image for user \(userId)")
				return cachedImage
			} else {
				// Return stale image immediately, refresh in background
				print("⚠️ [CACHE] Returning stale cached image for user \(userId), refreshing in background")
				Task.detached(priority: .background) {
					_ = await self.downloadAndCacheImage(from: urlString, for: userId, forceRefresh: true)
				}
				return cachedImage
			}
		}

		// No cached image - download
		print("❌ [CACHE] No cached image, downloading for user \(userId)")
		return await downloadAndCacheImage(from: urlString, for: userId, forceRefresh: false)
	}

	/// Download profile pictures for multiple users (sequentially)
	func refreshStaleProfilePictures(for users: [(userId: UUID, profilePictureUrl: String?)]) async {
		for user in users {
			guard let profilePictureUrl = user.profilePictureUrl else { continue }

			if isProfilePictureStale(for: user.userId) {
				_ = await downloadAndCacheImage(from: profilePictureUrl, for: user.userId, forceRefresh: true)
			}
		}
	}

	/// Force refresh a profile picture from the backend
	func refreshProfilePicture(for userId: UUID, from urlString: String) async -> UIImage? {
		return await downloadAndCacheImage(from: urlString, for: userId, forceRefresh: true)
	}

	/// Check if a cached profile picture is stale
	func isProfilePictureStale(for userId: UUID, maxAge: TimeInterval = 24 * 60 * 60) -> Bool {
		let key = userId.uuidString
		guard let metadata = cacheMetadata[key] else {
			return true
		}

		let ageInSeconds = Date().timeIntervalSince(metadata.cachedAt)
		return ageInSeconds > maxAge
	}

	/// Remove cached image for a user ID
	func removeCachedImage(for userId: UUID) {
		let key = userId.uuidString

		// Remove from memory cache
		memoryCache.removeObject(forKey: key as NSString)

		// Remove from disk
		let fileURL = cacheDirectory.appendingPathComponent("\(key).jpg")
		try? fileManager.removeItem(at: fileURL)

		// Remove metadata
		cacheMetadata.removeValue(forKey: key)
		saveMetadata()

		print("🗑️ [CACHE] Removed cached image for user \(userId)")
	}

	/// Clear all cached images
	func clearAllCache() {
		// Clear memory cache
		memoryCache.removeAllObjects()

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

	// MARK: - Private Methods - Disk Operations

	private func saveToDisk(_ image: UIImage, for key: String) async {
		guard let imageData = image.jpegData(compressionQuality: 0.8) else {
			print("❌ [CACHE] Failed to convert image to JPEG data for key \(key)")
			return
		}

		let fileURL = cacheDirectory.appendingPathComponent("\(key).jpg")

		do {
			try imageData.write(to: fileURL)
			print("✅ [CACHE] Saved to disk for key \(key)")

			// Update metadata
			let metadata = CacheMetadata(
				cachedAt: Date(),
				lastAccessed: Date(),
				fileSize: Int64(imageData.count)
			)
			await MainActor.run {
				self.cacheMetadata[key] = metadata
				self.saveMetadata()
			}

		} catch {
			print("❌ [CACHE] Failed to save image to disk for key \(key): \(error.localizedDescription)")
		}
	}

	// MARK: - Private Methods - Metadata

	private func updateLastAccessed(for key: String) {
		cacheMetadata[key]?.lastAccessed = Date()
	}

	private func loadMetadata() {
		guard let data = UserDefaults.standard.data(forKey: metadataKey),
			let metadata = try? JSONDecoder().decode([String: CacheMetadata].self, from: data)
		else {
			print("ℹ️ [CACHE] No existing metadata found")
			return
		}
		cacheMetadata = metadata
		print("✅ [CACHE] Loaded metadata for \(metadata.count) cached images")
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
