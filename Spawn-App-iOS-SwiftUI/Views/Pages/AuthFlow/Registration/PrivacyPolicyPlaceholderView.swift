//
//  PrivacyPolicyPlaceholderView.swift
//  Spawn-App-iOS-SwiftUI
//

import SwiftUI

struct PrivacyPolicyPlaceholderView: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme

	private var privacyPolicyURL: URL? { URL(string: ServiceConstants.URLs.privacyPolicy) }

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
			VStack(spacing: 20) {
				Text("Our Privacy Policy explains how we collect, use, and protect your data.")
					.font(.onestRegular(size: 16))
					.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
					.multilineTextAlignment(.center)
					.padding(.horizontal, 32)

				if let url = privacyPolicyURL {
					Button(action: {
						UIApplication.shared.open(url)
					}) {
						HStack(spacing: 8) {
							Image(systemName: "arrow.up.right.square")
								.font(.system(size: 18))
							Text("View Privacy Policy")
								.font(.onestSemiBold(size: 16))
						}
						.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
						.padding(.horizontal, 24)
						.padding(.vertical, 14)
						.background(
							RoundedRectangle(cornerRadius: 12)
								.stroke(
									universalAccentColor(from: themeService, environment: colorScheme), lineWidth: 1.5)
						)
					}
					.buttonStyle(PlainButtonStyle())
				}
			}
			Text("For questions, contact spawnappmarketing@gmail.com")
				.font(.onestRegular(size: 14))
				.foregroundColor(universalPlaceHolderTextColor(from: themeService, environment: colorScheme))
				.padding(.top, 24)
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
