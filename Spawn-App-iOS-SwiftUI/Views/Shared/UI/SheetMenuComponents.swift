//
//  SheetMenuComponents.swift
//  Spawn-App-iOS-SwiftUI
//
//  Shared building blocks for profile/friends sheet-style action menus.
//

import SwiftUI

/// Container for sheet-style menus with rounded corners and fixed vertical sizing.
struct SheetMenuContainer<Content: View>: View {
	private let content: Content

	init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}

	var body: some View {
		VStack(spacing: 8) {
			content
				.background(universalBackgroundColor)
				.cornerRadius(12)
		}
		.fixedSize(horizontal: false, vertical: true)
		.background(universalBackgroundColor)
	}
}

/// Single row in a sheet menu (icon + label, leading-aligned).
struct SheetMenuRow: View {
	let icon: String
	let text: String
	let color: Color
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			HStack(spacing: 10) {
				Image(systemName: icon)
					.font(.system(size: 20, weight: .medium))
					.foregroundColor(color)

				Text(text)
					.font(.system(size: 17, weight: .medium))
					.foregroundColor(color)

				Spacer()
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
			.frame(maxWidth: .infinity, minHeight: 63, alignment: .leading)
		}
	}
}

/// Cancel row with leading xmark, matching sheet menu styling.
struct SheetMenuCancelRow: View {
	let dismiss: DismissAction

	var body: some View {
		Button(action: { dismiss() }) {
			HStack(spacing: 10) {
				Image(systemName: "xmark")
					.font(.system(size: 20, weight: .medium))
					.foregroundColor(universalAccentColor)

				Text("Cancel")
					.font(.system(size: 17, weight: .medium))
					.foregroundColor(universalAccentColor)

				Spacer()
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
			.frame(maxWidth: .infinity, minHeight: 63, alignment: .leading)
		}
		.background(universalBackgroundColor)
		.cornerRadius(12)
	}
}

/// Placeholder shimmer while menu content loads.
struct SheetMenuLoadingPlaceholder: View {
	let rowCount: Int
	let dismiss: DismissAction

	var body: some View {
		VStack(spacing: 16) {
			ForEach(0..<rowCount, id: \.self) { _ in
				HStack {
					RoundedRectangle(cornerRadius: 4)
						.fill(Color.gray.opacity(0.2))
						.frame(height: 20)
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
			}

			Divider()

			Button(action: { dismiss() }) {
				Text("Cancel")
					.font(.headline)
					.foregroundColor(universalAccentColor)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 16)
			}
			.background(universalBackgroundColor)
			.cornerRadius(12)
		}
		.background(universalBackgroundColor)
		.redacted(reason: .placeholder)
		.shimmering()
	}
}
