//
//  LoadingStateView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created for DRY refactoring - Consolidates 34 duplicate ProgressView implementations

import SwiftUI

/// Unified loading state view with consistent styling
struct LoadingStateView: View {
	let message: String
	let scale: CGFloat

	init(message: String = "Loading...", scale: CGFloat = 1.2) {
		self.message = message
		self.scale = scale
	}

	var body: some View {
		VStack(spacing: 20) {
			ProgressView()
				.progressViewStyle(CircularProgressViewStyle())
				.scaleEffect(scale)

			Text(message)
				.font(.onestMedium(size: 16))
				.foregroundColor(figmaBlack300)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

@available(iOS 17, *)
#Preview {
	VStack(spacing: 40) {
		LoadingStateView()
		LoadingStateView(message: "Loading activities...")
		LoadingStateView(message: "Fetching data...", scale: 1.5)
	}
	.background(universalBackgroundColor)
}
