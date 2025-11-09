import SwiftUI

struct ErrorInputField: View {
	let placeholder: String
	@Binding var text: String
	let hasError: Bool
	let errorMessage: String?
	let isSecure: Bool

	init(
		placeholder: String, text: Binding<String>, hasError: Bool = false, errorMessage: String? = nil,
		isSecure: Bool = false
	) {
		self.placeholder = placeholder
		self._text = text
		self.hasError = hasError
		self.errorMessage = errorMessage
		self.isSecure = isSecure
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			// Input field with error styling
			HStack(spacing: 10) {
				if isSecure {
					SecureField(placeholder, text: $text)
						.font(Font.custom("Onest", size: 16).weight(.medium))
						.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
				} else {
					TextField(placeholder, text: $text)
						.font(Font.custom("Onest", size: 16).weight(.medium))
						.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
				}
			}
			.padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
			.frame(height: 63)
			.background(Color(hex: colorsGrayInput))
			.cornerRadius(16)
			.overlay(
				RoundedRectangle(cornerRadius: 16)
					.inset(by: 1)
					.stroke(hasError ? Color(red: 0.99, green: 0.31, blue: 0.30) : Color.clear, lineWidth: 1)
			)

			// Error message
			if hasError, let errorMessage = errorMessage {
				ErrorMessageView(message: errorMessage)
			}
		}
	}
}
