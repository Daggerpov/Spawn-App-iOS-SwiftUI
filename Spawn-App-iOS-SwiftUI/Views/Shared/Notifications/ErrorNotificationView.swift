import SwiftUI

struct ErrorNotificationView: View {
	let title: String
	let message: String

	var body: some View {
		HStack(spacing: 12) {
			// Error icon
			ZStack {
				Rectangle()
					.fill(Color.clear)
					.frame(width: 32, height: 32)
				// You can add an SF Symbol or custom icon here
			}

			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(Font.custom("Onest", size: 11).weight(.medium))
					.foregroundColor(Color(red: 1, green: 0.27, blue: 0.39).opacity(0.80))

				Text(message)
					.font(Font.custom("Onest", size: 16).weight(.bold))
					.foregroundColor(Color(red: 1, green: 0.27, blue: 0.39))
			}

			Spacer()
		}
		.padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
		.frame(maxWidth: .infinity)
		.background(Color(red: 1, green: 0.83, blue: 0.86))
		.cornerRadius(12)
		.overlay(
			RoundedRectangle(cornerRadius: 12)
				.stroke(Color(red: 1, green: 0.27, blue: 0.39), lineWidth: 0.50)
		)
		.shadow(
			color: Color(red: 0, green: 0, blue: 0, opacity: 0.25),
			radius: 8,
			y: 2
		)
	}
}

#Preview {
	ErrorNotificationView(
		title: "Alert",
		message: "This link has expired or is no longer available"
	)
	.padding()
	.background(Color(red: 0.12, green: 0.12, blue: 0.12))
}
