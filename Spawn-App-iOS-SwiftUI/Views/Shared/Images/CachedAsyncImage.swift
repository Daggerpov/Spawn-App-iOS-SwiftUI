//
//  CachedAsyncImage.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2025-01-03.
//

import SwiftUI
import UIKit

/// A cached version of AsyncImage that stores profile pictures locally
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
	let userId: UUID
	let url: URL?
	let content: (Image) -> Content
	let placeholder: () -> Placeholder

	@State private var image: UIImage?
	@State private var isLoading = false
	@State private var loadError: Error?

	private let cache = ProfilePictureCache.shared

	init(
		userId: UUID,
		url: URL?,
		@ViewBuilder content: @escaping (Image) -> Content,
		@ViewBuilder placeholder: @escaping () -> Placeholder
	) {
		self.userId = userId
		self.url = url
		self.content = content
		self.placeholder = placeholder
	}

	var body: some View {
		Group {
			if let image = image {
				content(Image(uiImage: image))
			} else if isLoading {
				placeholder()
			} else if loadError != nil {
				placeholder()
			} else {
				placeholder()
			}
		}
		.onAppear {
			loadImage()
		}
		.onChange(of: url) { _, newURL in
			loadImage()
		}
	}

	private func loadImage() {
		// Reset state
		loadError = nil

		print("🖼️ [UI] CachedAsyncImage loadImage called for user \(userId)")
		print("   URL: \(url?.absoluteString ?? "nil")")

		// If no URL, nothing to load
		guard let url = url else {
			print("❌ [UI] CachedAsyncImage: No URL provided for user \(userId)")
			return
		}

		let loadStartTime = Date()

		// Start loading
		isLoading = true
		print("⏳ [UI] CachedAsyncImage: Starting load for user \(userId)")

		Task {
			// Use the new refresh mechanism that checks for staleness
			let downloadedImage = await cache.getCachedImageWithRefresh(
				for: userId,
				from: url.absoluteString,
				maxAge: 6 * 60 * 60  // 6 hours for more frequent updates
			)

			let loadDuration = Date().timeIntervalSince(loadStartTime)

			await MainActor.run {
				isLoading = false
				image = downloadedImage
				if downloadedImage == nil {
					print("❌ [UI] CachedAsyncImage failed to load for user \(userId)")
					print("   URL was: \(url.absoluteString)")
					print("   Load duration: \(String(format: "%.2f", loadDuration))s")
					loadError = NSError(
						domain: "CachedAsyncImage", code: 0,
						userInfo: [NSLocalizedDescriptionKey: "Failed to download image"])
				} else {
					if loadDuration > 1.0 {
						print(
							"⏱️ [UI] CachedAsyncImage loaded in \(String(format: "%.2f", loadDuration))s for user \(userId)"
						)
					} else {
						print(
							"✅ [UI] CachedAsyncImage loaded successfully for user \(userId) in \(String(format: "%.2f", loadDuration))s"
						)
					}
				}
			}
		}
	}
}

// MARK: - Convenience Initializers

extension CachedAsyncImage where Content == Image, Placeholder == Color {
	/// Simple initializer that shows a gray placeholder
	init(userId: UUID, url: URL?) {
		self.init(
			userId: userId,
			url: url,
			content: { image in image },
			placeholder: { Color.gray }
		)
	}
}

extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
	/// Initializer with progress view placeholder
	init(userId: UUID, url: URL?, @ViewBuilder content: @escaping (Image) -> Content) {
		self.init(
			userId: userId,
			url: url,
			content: content,
			placeholder: { ProgressView() }
		)
	}
}

extension CachedAsyncImage where Content == Image {
	/// Initializer with custom placeholder
	init(userId: UUID, url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
		self.init(
			userId: userId,
			url: url,
			content: { image in image },
			placeholder: placeholder
		)
	}
}

// MARK: - Profile Picture Specific Views
// All profile-specific view structs have been moved to separate files in CachedAsyncImage/
// - CachedProfileImage.swift
// - CachedProfileImageFlexible.swift
