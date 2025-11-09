import SwiftUI

// MARK: - Social Media Field
struct SocialMediaField: View {
	let icon: String
	let placeholder: String
	@Binding var text: String
	var keyboardType: UIKeyboardType = .default

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			// Add descriptive label based on platform
			Text(icon == "instagram" ? "Instagram Username" : "WhatsApp Number")
				.font(.subheadline)
				.foregroundColor(.gray)

			HStack {
				Image(icon)
					.resizable()
					.scaledToFit()
					.frame(width: 30, height: 30)
					.padding(.trailing, 8)

				// Add @ prefix for Instagram
				if icon == "instagram" && !text.hasPrefix("@") && !text.isEmpty {
					Text("@")
						.foregroundColor(.gray)
				}

				TextField(placeholder, text: $text)
					.font(.subheadline)
					.foregroundColor(universalAccentColor)
					.keyboardType(keyboardType)
					.placeholder(when: text.isEmpty) {
						Text(placeholder)
							.foregroundColor(universalAccentColor.opacity(0.7))
							.font(.subheadline)
					}

				Spacer()
			}
			.padding()
			.cornerRadius(10)
			.overlay(
				RoundedRectangle(
					cornerRadius: universalNewRectangleCornerRadius
				)
				// TODO DANIEL A: adjust this color to be the gradient of the logo, like in Figma
				.stroke(
					icon == "instagram"
						? Color(red: 1, green: 0.83, blue: 0.33) : Color(red: 0.37, green: 0.98, blue: 0.47),
					lineWidth: 1)
			)

			// Add helpful hint text
			Text(
				icon == "instagram" ? "Enter your Instagram handle (with or without @)" : "Only for your friends to see"
			)
			.font(.caption)
			.foregroundColor(.gray)
			.padding(.leading, 2)
		}
	}
}
