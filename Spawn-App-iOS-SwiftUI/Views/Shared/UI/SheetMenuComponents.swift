//
//  SheetMenuComponents.swift
//  Spawn-App-iOS-SwiftUI
//
//  Shared building blocks for profile/friends sheet-style action menus.
//

import SwiftUI

/// Container for sheet-style menus. Sizes the sheet to the measured rows so no gap or
/// system sheet background shows around them, and scrolls if the rows outgrow the screen.
struct SheetMenuContainer<Content: View>: View {
	private let rowCount: Int
	private let content: Content
	@State private var contentHeight: CGFloat = 0

	/// - Parameter rowCount: Number of rows including Cancel, used for the height until the rows are measured.
	init(rowCount: Int, @ViewBuilder content: () -> Content) {
		self.rowCount = rowCount
		self.content = content()
	}

	private var initialHeight: CGFloat {
		// 63pt rows separated by 1pt dividers.
		CGFloat(rowCount) * 63 + CGFloat(rowCount - 1)
	}

	var body: some View {
		ScrollView {
			content
				.background {
					GeometryReader { geometry in
						Color.clear.preference(key: SheetMenuHeightKey.self, value: geometry.size.height)
					}
				}
		}
		.scrollBounceBehavior(.basedOnSize)
		.background(universalBackgroundColor)
		.presentationBackground(universalBackgroundColor)
		.presentationDragIndicator(.hidden)
		.presentationDetents([.height(contentHeight > 0 ? contentHeight : initialHeight)])
		.onPreferenceChange(SheetMenuHeightKey.self) { height in
			if height > 0 {
				contentHeight = height
			}
		}
	}
}

private struct SheetMenuHeightKey: PreferenceKey {
	static var defaultValue: CGFloat { 0 }

	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = max(value, nextValue())
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
					.frame(width: 24, height: 24)
					.foregroundColor(color)

				Text(text)
					.font(.system(size: 17, weight: .medium))
					.foregroundColor(color)

				Spacer()
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
			.frame(maxWidth: .infinity, minHeight: 63, alignment: .leading)
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
	}
}

/// Cancel row with leading xmark, matching sheet menu styling.
struct SheetMenuCancelRow: View {
	let dismiss: DismissAction

	var body: some View {
		SheetMenuRow(icon: "xmark", text: "Cancel", color: universalAccentColor) {
			dismiss()
		}
		.background(universalBackgroundColor)
	}
}
