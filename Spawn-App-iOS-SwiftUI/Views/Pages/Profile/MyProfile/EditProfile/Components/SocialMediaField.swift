import SwiftUI

// MARK: - Instagram Gradient Colors
private let instagramGradientColors: [Color] = [
	Color(hex: colorsPurple500),  // Purple
	Color(hex: colorsPink500),  // Pink
	Color(hex: colorsRed500),  // Red/Orange
	Color(hex: colorsYellow400),  // Yellow
]

// MARK: - WhatsApp Gradient Colors
private let whatsappGradientColors: [Color] = [
	Color(hex: colorsGreen400),  // Light green
	Color(hex: colorsGreen600),  // Medium green
]

// MARK: - Social Media Field
struct SocialMediaField: View {
	let icon: String
	let placeholder: String
	@Binding var text: String
	var keyboardType: UIKeyboardType = .default

	private var gradientColors: [Color] {
		icon == "instagram" ? instagramGradientColors : whatsappGradientColors
	}

	private var gradient: LinearGradient {
		LinearGradient(
			colors: gradientColors,
			startPoint: icon == "instagram" ? .topLeading : .leading,
			endPoint: icon == "instagram" ? .bottomTrailing : .trailing
		)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			// Add descriptive label based on platform
			Text(icon == "instagram" ? "Instagram Username" : "WhatsApp Number")
				.font(.subheadline)
				.foregroundColor(.gray)

			HStack(spacing: 12) {
				Image(icon)
					.resizable()
					.scaledToFit()
					.frame(width: 28, height: 28)

				// Add @ prefix for Instagram
				if icon == "instagram" {
					Text("@")
						.foregroundColor(.gray)
						.font(.subheadline)
				}

				TextField(placeholder, text: $text)
					.font(.subheadline)
					.foregroundColor(universalAccentColor)
					.keyboardType(keyboardType)
					.placeholder(when: text.isEmpty) {
						Text(placeholder)
							.foregroundColor(universalAccentColor.opacity(0.5))
							.font(.subheadline)
					}

				Spacer()
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 14)
			.background(
				RoundedRectangle(cornerRadius: universalNewRectangleCornerRadius)
					.fill(Color.clear)
			)
			.overlay(
				RoundedRectangle(cornerRadius: universalNewRectangleCornerRadius)
					.stroke(gradient, lineWidth: 1.5)
			)

			// Add helpful hint text
			Text(
				icon == "instagram"
					? "Enter your Instagram handle (with or without @)" : "Only for your friends to see"
			)
			.font(.caption)
			.foregroundColor(.gray)
			.padding(.leading, 2)
		}
	}
}
