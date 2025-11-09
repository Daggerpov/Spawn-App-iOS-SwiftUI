//
//  LoadingView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2024-08-02.
//

import SwiftUI

struct LoadingView: View {
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme

	var body: some View {
		VStack {
			Spacer()

			// Rive animation - falls back to static logo if .riv file not found
			RiveAnimationView.loadingAnimation(fileName: "spawn_logo_animation")
				.frame(width: 300, height: 300)

			Spacer()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(universalBackgroundColor(from: themeService, environment: colorScheme))
		.ignoresSafeArea(.all)  // Ignore all safe areas including top and bottom
	}
}

#Preview {
	LoadingView()
}
