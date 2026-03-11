//
//  PrivacyPolicyPlaceholderView.swift
//  Spawn-App-iOS-SwiftUI
//

import SwiftUI

struct PrivacyPolicyPlaceholderView: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				UnifiedBackButton { dismiss() }
				Spacer()
				Text("Privacy Policy")
					.font(.onestSemiBold(size: 18))
					.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
				Spacer()
				Color.clear.frame(width: 44, height: 44)
			}
			.padding(.horizontal, 25)
			.padding(.vertical, 12)

			Spacer()
			Text("Our full Privacy Policy will be available here or via a link in the app.")
				.font(.onestRegular(size: 16))
				.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
				.multilineTextAlignment(.center)
				.padding(.horizontal, 32)
			Text("For questions, contact spawnappmarketing@gmail.com")
				.font(.onestRegular(size: 14))
				.foregroundColor(universalPlaceHolderTextColor(from: themeService, environment: colorScheme))
				.padding(.top, 12)
				.padding(.horizontal, 32)
			Spacer()
		}
		.background(universalBackgroundColor(from: themeService, environment: colorScheme).ignoresSafeArea())
		.navigationBarHidden(true)
	}
}

#Preview {
	PrivacyPolicyPlaceholderView()
}
