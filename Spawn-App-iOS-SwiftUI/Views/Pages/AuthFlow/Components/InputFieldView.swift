import SwiftUI

struct InputFieldView: View {
	var label: String
	@Binding var text: String
	@Binding var isValid: Bool
	var placeholder: String
	
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme

	init(label: String, text: Binding<String>, isValid: Binding<Bool>, placeholder: String = "") {
		self.label = label
		self._text = text
		self._isValid = isValid
		self.placeholder = placeholder
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack {
				Text(label)
					.font(.system(size: 18))
					.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))

				if !isValid {
					Image(systemName: "exclamationmark.circle.fill")
						.foregroundColor(.red)
						.font(.system(size: 12))
				}
			}

			TextField(placeholder, text: $text)
				.padding()
				.background(getInputFieldBackgroundColor())
				.cornerRadius(universalRectangleCornerRadius)
				.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
				.accentColor(universalAccentColor(from: themeService, environment: colorScheme))
				.autocapitalization(.none)
				.autocorrectionDisabled(true)
				.overlay(
					RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
						.stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
				)
		}
	}
	
	private func getInputFieldBackgroundColor() -> Color {
		// Use a theme-aware background color for input fields
		let currentScheme = themeService.colorScheme
		switch currentScheme {
		case .light:
			return Color(hex: colorsGrayInput)
		case .dark:
			return Color(hex: "#2C2C2C")
		case .system:
			return colorScheme == .dark ? Color(hex: "#2C2C2C") : Color(hex: colorsGrayInput)
		}
	}
}

