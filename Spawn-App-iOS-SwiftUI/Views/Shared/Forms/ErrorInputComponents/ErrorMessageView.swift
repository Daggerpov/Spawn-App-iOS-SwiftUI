import SwiftUI

struct ErrorMessageView: View {
	let message: String

	var body: some View {
		HStack(spacing: 8) {
			// Error icon
			Image(systemName: "exclamationmark.triangle.fill")
				.font(.system(size: 12))
				.foregroundColor(Color(red: 0.92, green: 0.26, blue: 0.21))

			// Error message text
			Text(message)
				.font(Font.custom("Onest", size: 14).weight(.medium))
				.foregroundColor(Color(red: 0.92, green: 0.26, blue: 0.21))
				.multilineTextAlignment(.leading)

			Spacer()
		}
		.padding(.leading, 16)
	}
}
