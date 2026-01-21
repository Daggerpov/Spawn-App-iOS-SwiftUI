import SwiftUI

// MARK: - Social Media Section
struct SocialMediaSection: View {
	@Binding var whatsappLink: String
	@Binding var instagramLink: String

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("Social Media")
				.font(.system(size: 18, weight: .semibold))
				.foregroundColor(universalAccentColor)

			// Instagram
			SocialMediaField(
				icon: "instagram",
				placeholder: "username",
				text: $instagramLink
			)

			// WhatsApp
			SocialMediaField(
				icon: "whatsapp",
				placeholder: "+1 234 567 8901",
				text: $whatsappLink,
				keyboardType: .phonePad
			)
		}
		.padding(.horizontal)
	}
}
