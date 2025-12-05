import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
	@Environment(\.colorScheme) var colorScheme

	func _body(configuration: TextField<Self._Label>) -> some View {
		configuration
			.padding(.horizontal, 16)
			.padding(.vertical, 20)
			.background(getInputFieldBackgroundColor())
			.cornerRadius(16)
			.font(.onestRegular(size: 16))
			.foregroundColor(getAccentColor())
			.accentColor(getAccentColor())
	}

	private func getAccentColor() -> Color {
		// Compute accent color based on color scheme without MainActor dependency
		switch colorScheme {
		case .dark:
			return Color(hex: colorsWhite)
		case .light:
			return Color(hex: colorsGray900)
		@unknown default:
			return Color(hex: colorsGray900)
		}
	}

	private func getInputFieldBackgroundColor() -> Color {
		// Use a theme-aware background color for input fields
		switch colorScheme {
		case .dark:
			return Color(hex: "#2C2C2C")
		case .light:
			return Color(hex: colorsGrayInput)
		@unknown default:
			return Color(hex: colorsGrayInput)
		}
	}
}
