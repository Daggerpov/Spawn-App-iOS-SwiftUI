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
		guard let urlString = urlString else {
			print("❌ [DOWNLOAD] No URL provided for user \(userId)")
			return nil
		}

		return await downloadAndCacheImage(from: urlString, for: userId, forceRefresh: false)
	}

	/// Download profile pictures for multiple users (sequentially)
	func refreshStaleProfilePictures(for users: [(userId: UUID, profilePictureUrl: String?)]) async {
		for user in users {
			guard let profilePictureUrl = user.profilePictureUrl else { continue }
			_ = await downloadAndCacheImage(from: profilePictureUrl, for: user.userId, forceRefresh: false)
		}
	}

	/// Force refresh a profile picture from the backend
	func refreshProfilePicture(for userId: UUID, from urlString: String) async -> UIImage? {
		return await downloadAndCacheImage(from: urlString, for: userId, forceRefresh: false)
	}

	/// Remove cached image for a user ID (no-op)
	func removeCachedImage(for userId: UUID) {
		// No-op - we don't cache
	}

	/// Clear all cached images (no-op)
	func clearAllCache() {
		// No-op - we don't cache
	}
}
