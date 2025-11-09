//
//  UnifiedBackButton.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created for DRY refactoring - Consolidates 47 duplicate back button implementations

import SwiftUI

/// Unified back button with consistent styling and behavior
struct UnifiedBackButton: View {
	let title: String?
	let action: () -> Void

	init(title: String? = nil, action: @escaping () -> Void) {
		self.title = title
		self.action = action
	}

	var body: some View {
		Button(action: {
			HapticFeedbackService.shared.light()
			action()
		}) {
			HStack(spacing: 4) {
				Image(systemName: "chevron.left")
					.font(.system(size: 20, weight: .semibold))

				if let title = title {
					Text(title)
						.font(.system(size: 17))
				}
			}
			.foregroundColor(universalAccentColor)
		}
		.buttonStyle(PlainButtonStyle())
	}
}

/// Environment-aware back button that uses dismiss
struct UnifiedDismissButton: View {
	@Environment(\.presentationMode) var presentationMode
	let title: String?

	init(title: String? = "Back") {
		self.title = title
	}

	var body: some View {
		UnifiedBackButton(title: title) {
			presentationMode.wrappedValue.dismiss()
		}
	}
}

@available(iOS 17, *)
#Preview {
	VStack(spacing: 20) {
		HStack {
			UnifiedBackButton {
				print("Back tapped")
			}
			Spacer()
		}

		HStack {
			UnifiedBackButton(title: "Back") {
				print("Back with text tapped")
			}
			Spacer()
		}

		HStack {
			UnifiedDismissButton()
			Spacer()
		}
	}
	.padding()
	.background(universalBackgroundColor)
}
