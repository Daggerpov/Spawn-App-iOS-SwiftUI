import SwiftUI

// Error-aware text field component with red borders
struct ErrorTextFieldStyle: TextFieldStyle {
	let hasError: Bool
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
			.overlay(
				RoundedRectangle(cornerRadius: 16)
					.inset(by: 1)
					.stroke(hasError ? Color(red: 0.77, green: 0.19, blue: 0.19) : Color.clear, lineWidth: 1)
			)
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
