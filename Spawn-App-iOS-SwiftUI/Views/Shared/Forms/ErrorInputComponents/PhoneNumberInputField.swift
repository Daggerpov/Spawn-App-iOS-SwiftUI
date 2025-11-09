import SwiftUI

struct PhoneNumberInputField: View {
	@Binding var phoneNumber: String
	let hasError: Bool
	let errorMessage: String?
	@FocusState private var isPhoneFieldFocused: Bool

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			// Phone number input field
			HStack(spacing: 10) {
				Text("+1")
					.font(Font.custom("Onest", size: 16).weight(.medium))
					.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))

				TextField("778-100-1000", text: $phoneNumber)
					.font(Font.custom("Onest", size: 16).weight(.medium))
					.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
					.keyboardType(.numberPad)
					.focused($isPhoneFieldFocused)
					.toolbar {
						ToolbarItemGroup(placement: .keyboard) {
							Spacer()
							Button("Done") {
								isPhoneFieldFocused = false
								// Force dismiss keyboard for number pad
								UIApplication.shared.sendAction(
									#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
							}
							.font(.onestMedium(size: 16))
							.foregroundColor(.blue)
						}
					}
					.onSubmit {
						isPhoneFieldFocused = false
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
