//
//  EmptyStateView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created for DRY refactoring - Consolidates 22 duplicate empty state implementations

import SwiftUI

/// Unified empty state view with consistent styling
struct EmptyStateView: View {
	let imageName: String?
	let systemImageName: String?
	let title: String
	let subtitle: String?
	let imageSize: CGFloat

	init(
		imageName: String? = nil,
		systemImageName: String? = nil,
		title: String,
		subtitle: String? = nil,
		imageSize: CGFloat = 125
	) {
		self.imageName = imageName
		self.systemImageName = systemImageName
		self.title = title
		self.subtitle = subtitle
		self.imageSize = imageSize
	}

	var body: some View {
		VStack(spacing: 16) {
			Spacer()

			// Image (either custom asset or SF Symbol)
			if let imageName = imageName {
				Image(imageName)
					.resizable()
					.scaledToFit()
					.frame(width: imageSize, height: imageSize)
			} else if let systemImageName = systemImageName {
				Image(systemName: systemImageName)
					.resizable()
					.scaledToFit()
					.frame(width: imageSize * 0.6, height: imageSize * 0.6)
					.foregroundColor(universalAccentColor.opacity(0.7))
			}

			// Title
			Text(title)
				.font(.onestSemiBold(size: 24))
				.foregroundColor(universalAccentColor)

			// Subtitle (optional)
			if let subtitle = subtitle {
				Text(subtitle)
					.font(.onestMedium(size: 16))
					.foregroundColor(figmaBlack300)
					.multilineTextAlignment(.center)
					.padding(.horizontal)
			}

			Spacer()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

// MARK: - Convenience Initializers

extension EmptyStateView {
	/// Empty state for no activities found
	static func noActivities() -> EmptyStateView {
		EmptyStateView(
			imageName: "NoActivitiesFound",
			title: "No Activities Found",
			subtitle: "We couldn't find any activities nearby.\nStart one yourself and be spontaneous!"
		)
	}

	/// Empty state for no activities on a specific day
	static func noActivitiesForDay() -> EmptyStateView {
		EmptyStateView(
			imageName: "NoActivitiesFound",
			title: "No activities for this day",
			subtitle: "Check out other days or create\nyour own activity!"
		)
	}

	/// Empty state for all good / no reports
	static func allGood() -> EmptyStateView {
		EmptyStateView(
			systemImageName: "checkmark.shield",
			title: "All Good!",
			subtitle:
				"Looks like you haven't found anything to report...yet. Thank you for helping keep our community safe.",
			imageSize: 100
		)
	}

	/// Empty state for no friend requests
	static func noFriendRequests() -> EmptyStateView {
		EmptyStateView(
			systemImageName: "person.2",
			title: "No Friend Requests",
			subtitle: "When someone sends you a friend request,\nit will appear here."
		)
	}

	/// Empty state for no search results
	static func noSearchResults() -> EmptyStateView {
		EmptyStateView(
			systemImageName: "magnifyingglass",
			title: "No Results Found",
			subtitle: "Try a different search term or check your spelling."
		)
	}
}

@available(iOS 17, *)
#Preview {
	VStack(spacing: 40) {
		EmptyStateView.noActivities()
		EmptyStateView.allGood()
		EmptyStateView(
			systemImageName: "star",
			title: "Custom Empty State",
			subtitle: "This is a custom empty state"
		)
	}
	.background(universalBackgroundColor)
}
