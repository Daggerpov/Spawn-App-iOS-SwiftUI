//
//  TermsAndConditionsView.swift
//  Spawn-App-iOS-SwiftUI
//

import SwiftUI

struct TermsAndConditionsView: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				UnifiedBackButton { dismiss() }
				Spacer()
				Text("Terms and Conditions")
					.font(.onestSemiBold(size: 18))
					.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
				Spacer()
				// Balance back button
				Color.clear.frame(width: 44, height: 44)
			}
			.padding(.horizontal, 25)
			.padding(.vertical, 12)

			ScrollView {
				VStack(alignment: .leading, spacing: 20) {
					Text("March 2nd 2025")
						.font(.onestMedium(size: 14))
						.foregroundColor(universalPlaceHolderTextColor(from: themeService, environment: colorScheme))

					sectionTitle("1. Introduction")
					bodyText(
						"Welcome to Spawn! These Terms and Conditions (\"Terms\") govern your use of the Spawn mobile application (\"App\"), which allows users to discover and join friends' activities in real time. By accessing or using Spawn, you agree to comply with these Terms. If you do not agree, please do not use the App."
					)

					sectionTitle("2. Eligibility")
					bodyText(
						"You must be at least 13 years old to use Spawn. If you are under 18, you must have parental or legal guardian consent. By using the App, you confirm that you meet these requirements."
					)

					sectionTitle("3. User Accounts")
					bodyText("You are responsible for maintaining the confidentiality of your account credentials.")
					bodyText(
						"You agree not to share your account with others or use another person's account without permission."
					)
					bodyText("Spawn reserves the right to suspend or terminate accounts that violate these Terms.")

					sectionTitle("4. Acceptable Use")
					bodyText("When using Spawn, you agree to:")
					bodyText("Share and engage with activities responsibly and respectfully.")
					bodyText("Not post false, misleading, or inappropriate content.")
					bodyText("Not use the App for illegal, harmful, or fraudulent purposes.")
					bodyText("Not attempt to hack, disrupt, or exploit the App.")

					sectionTitle("5. Privacy Policy")
					bodyText(
						"Your use of Spawn is subject to our Privacy Policy, which explains how we collect, use, and protect your data. By using Spawn, you agree to our data practices. Include link to Privacy Policy"
					)

					sectionTitle("6. Location Services")
					bodyText(
						"Spawn uses real-time location data to enhance user experience. You acknowledge and agree that your location may be shared with friends based on your selected privacy settings."
					)

					sectionTitle("7. Intellectual Property")
					bodyText(
						"Spawn and its associated trademarks, logos, and content are the exclusive property of [Company Name]."
					)
					bodyText("Users may not copy, modify, or distribute any content from Spawn without permission.")

					sectionTitle("8. Limitation of Liability")
					bodyText(
						"Spawn is provided \"as is\" without warranties of any kind. We do not guarantee uninterrupted or error-free service. Spawn is not responsible for any loss, damages, or disputes arising from use of the App."
					)

					sectionTitle("9. Third-Party Links & Services")
					bodyText(
						"Spawn may contain links to third-party websites or services. We do not control or endorse these services and are not responsible for their content or policies."
					)

					sectionTitle("10. Termination")
					bodyText(
						"We reserve the right to suspend or terminate your access to Spawn at our discretion if you violate these Terms or engage in harmful activities on the App."
					)

					sectionTitle("11. Changes to Terms")
					bodyText(
						"Spawn may update these Terms periodically. Continued use of the App after changes constitutes acceptance of the updated Terms."
					)

					sectionTitle("12. Contact Us")
					bodyText(
						"If you have any questions about these Terms, please contact us at spawnappmarketing@gmail.com."
					)

					bodyText(
						"By using Spawn, you acknowledge that you have read, understood, and agreed to these Terms and Conditions."
					)
					.padding(.top, 8)
				}
				.padding(.horizontal, 24)
				.padding(.bottom, 32)
			}
		}
		.background(universalBackgroundColor(from: themeService, environment: colorScheme).ignoresSafeArea())
		.navigationBarHidden(true)
	}

	private func sectionTitle(_ text: String) -> some View {
		Text(text)
			.font(.onestSemiBold(size: 16))
			.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
	}

	private func bodyText(_ text: String) -> some View {
		Text(text)
			.font(.onestRegular(size: 15))
			.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
			.fixedSize(horizontal: false, vertical: true)
	}
}

#Preview {
	TermsAndConditionsView()
}
