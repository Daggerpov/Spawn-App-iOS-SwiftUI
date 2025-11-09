//
//  UnifiedNavigationHeader.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created for DRY refactoring - Consolidates repeated navigation header patterns

import SwiftUI

/// Unified navigation header with customizable leading, center, and trailing items
struct UnifiedNavigationHeader: View {
	let title: String?
	let showBackButton: Bool
	let backButtonAction: (() -> Void)?
	let trailingContent: (() -> AnyView)?

	init(
		title: String? = nil,
		showBackButton: Bool = true,
		backButtonAction: (() -> Void)? = nil,
		@ViewBuilder trailingContent: @escaping () -> some View = { EmptyView() }
	) {
		self.title = title
		self.showBackButton = showBackButton
		self.backButtonAction = backButtonAction
		self.trailingContent = { AnyView(trailingContent()) }
	}

	var body: some View {
		HStack {
			// Leading: Back button
			if showBackButton {
				if let backButtonAction = backButtonAction {
					UnifiedBackButton(action: backButtonAction)
				} else {
					UnifiedDismissButton(title: nil)
				}
			} else {
				Color.clear.frame(width: 24, height: 24)
			}

			Spacer()

			// Center: Title
			if let title = title {
				Text(title)
					.font(.headline)
					.foregroundColor(universalAccentColor)
			}

			Spacer()

			// Trailing: Custom content
			if let trailingContent = trailingContent {
				trailingContent()
			} else {
				Color.clear.frame(width: 24, height: 24)
			}
		}
		.padding(.horizontal)
		.padding(.top, 8)
		.padding(.bottom, 16)
	}
}

// MARK: - Convenience Initializers

extension UnifiedNavigationHeader {
	/// Header with only a back button
	static func withBackButton(action: @escaping () -> Void) -> UnifiedNavigationHeader {
		UnifiedNavigationHeader(
			showBackButton: true,
			backButtonAction: action
		)
	}

	/// Header with back button and title
	static func withTitle(_ title: String, backButtonAction: (() -> Void)? = nil) -> UnifiedNavigationHeader {
		UnifiedNavigationHeader(
			title: title,
			showBackButton: true,
			backButtonAction: backButtonAction
		)
	}
}

@available(iOS 17, *)
#Preview {
	VStack(spacing: 40) {
		UnifiedNavigationHeader.withBackButton {
			print("Back tapped")
		}

		UnifiedNavigationHeader.withTitle("My Reports")

		UnifiedNavigationHeader(
			title: "Settings",
			showBackButton: true,
			backButtonAction: { print("Back") }
		) {
			Image(systemName: "gearshape")
				.foregroundColor(universalAccentColor)
		}
	}
	.background(universalBackgroundColor)
}
