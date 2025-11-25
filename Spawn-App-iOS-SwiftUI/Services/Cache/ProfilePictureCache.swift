//
//  ProfilePictureCache.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2025-01-03.
//

import Foundation
import SwiftUI
import UIKit

/// A singleton service that manages simple profile picture downloading
class ProfilePictureCache: ObservableObject {
	static let shared = ProfilePictureCache()

	// MARK: - Initialization
	private init() {
		// Simple initialization
	}

	// MARK: - Public Methods

	/// Download an image from a URL for a user ID (no caching, no complexity)
	func downloadAndCacheImage(from urlString: String, for userId: UUID, forceRefresh: Bool = false) async -> UIImage? {
		print("🌐 [DOWNLOAD] Downloading image for user \(userId)")
		print("   URL: \(urlString)")

		guard let url = URL(string: urlString) else {
			print("❌ [DOWNLOAD] Invalid URL: \(urlString)")
			return nil
		}

		do {
			let (data, response) = try await URLSession.shared.data(from: url)

			if let httpResponse = response as? HTTPURLResponse {
				print("   HTTP Status: \(httpResponse.statusCode)")
			}

			guard let image = UIImage(data: data) else {
				print("❌ [DOWNLOAD] Failed to create image from data for user \(userId)")
				return nil
			}

			print("✅ [DOWNLOAD] Successfully downloaded image for user \(userId)")
			return image

		} catch {
			print("❌ [DOWNLOAD] Download failed for user \(userId): \(error.localizedDescription)")
			return nil
		}
	}

	/// Get an image with automatic download (no caching)
	/// This is the main entry point for UI components
	func getCachedImageWithRefresh(for userId: UUID, from urlString: String?, maxAge: TimeInterval = 24 * 60 * 60) async
		-> UIImage?
	{
		print("🔄 [DOWNLOAD] getCachedImageWithRefresh for user \(userId)")
		print("   URL: \(urlString ?? "nil")")

		guard let urlString = urlString else {
			print("❌ [DOWNLOAD] No URL provided for user \(userId), cannot download")
			return nil
		}

		return await downloadAndCacheImage(from: urlString, for: userId, forceRefresh: false)
	}

	/// Download profile pictures for multiple users in parallel
	/// Uses task groups to download multiple profile pictures in parallel for faster performance
	func refreshStaleProfilePictures(for users: [(userId: UUID, profilePictureUrl: String?)]) async {
		// Use withTaskGroup to download multiple profile pictures in parallel
		await withTaskGroup(of: Void.self) { group in
			for user in users {
				guard let profilePictureUrl = user.profilePictureUrl else { continue }

				group.addTask {
					_ = await self.downloadAndCacheImage(from: profilePictureUrl, for: user.userId, forceRefresh: false)
				}
			}
		}
	}

	/// Force refresh a profile picture from the backend
	/// This is an alias for downloadAndCacheImage for backwards compatibility
	func refreshProfilePicture(for userId: UUID, from urlString: String) async -> UIImage? {
		return await downloadAndCacheImage(from: urlString, for: userId, forceRefresh: false)
	}

	/// Remove cached image for a user ID
	/// No-op since we don't cache anymore
	func removeCachedImage(for userId: UUID) {
		// No-op - we don't have a cache to remove from
		print("ℹ️ [DOWNLOAD] removeCachedImage called but no cache exists (userId: \(userId))")
	}

	/// Clear all cached images
	/// No-op since we don't cache anymore
	func clearAllCache() {
		// No-op - we don't have a cache to clear
		print("ℹ️ [DOWNLOAD] clearAllCache called but no cache exists")
	}

	// MARK: - Private Methods - Download Task Management

	private func getDownloadTask(_ key: String) -> Task<UIImage?, Never>? {
		return downloadingQueue.sync {
			return downloadingImages[key]
		}
	}

	private func setDownloadTask(_ task: Task<UIImage?, Never>, for key: String) {
		downloadingQueue.async(flags: .barrier) {
			self.downloadingImages[key] = task
		}
	}

	private func removeDownloadTask(for key: String) {
		downloadingQueue.async(flags: .barrier) {
			self.downloadingImages.removeValue(forKey: key)
		}
	}

	// MARK: - Failed Downloads Tracking

	private func isInFailureCooldown(_ urlString: String) -> Bool {
		return failedDownloadsQueue.sync {
			guard let failureDate = failedDownloads[urlString] else { return false }
			let timeSinceFailure = Date().timeIntervalSince(failureDate)
			return timeSinceFailure < failedDownloadCooldown
		}
	}

	private func markDownloadFailed(_ urlString: String) {
		failedDownloadsQueue.async(flags: .barrier) {
			self.failedDownloads[urlString] = Date()
		}
	}

	private func clearDownloadFailure(_ urlString: String) {
		failedDownloadsQueue.async(flags: .barrier) {
			self.failedDownloads.removeValue(forKey: urlString)
		}
	}
}
