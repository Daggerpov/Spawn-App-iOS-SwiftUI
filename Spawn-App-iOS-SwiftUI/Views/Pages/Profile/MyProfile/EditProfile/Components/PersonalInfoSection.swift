import SwiftUI

// MARK: - Personal Info Section
struct PersonalInfoSection: View {
	@Binding var name: String
	@Binding var username: String

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			// Name field
			VStack(alignment: .leading, spacing: 6) {
				Text("Name")
					.font(.subheadline)
					.foregroundColor(.gray)

				TextField("Full Name", text: $name)
					.font(.subheadline)
					.padding()
					.foregroundColor(universalAccentColor)
					.cornerRadius(10)
					.overlay(
						RoundedRectangle(
							cornerRadius: universalNewRectangleCornerRadius
						)
						.stroke(universalAccentColor, lineWidth: 1)
					)
					.placeholder(when: name.isEmpty) {
						Text("Full Name")
							.foregroundColor(universalAccentColor.opacity(0.7))
							.font(.subheadline)
							.padding(.leading)
					}
			}

			// Username field
			VStack(alignment: .leading, spacing: 6) {
				Text("Username")
					.font(.subheadline)
					.foregroundColor(.gray)

				HStack {
					Text("@")
						.foregroundColor(.gray)

					TextField("username", text: $username)
						.foregroundColor(universalAccentColor)
						.font(.subheadline)
						.placeholder(when: username.isEmpty) {
							Text("username")
								.foregroundColor(universalAccentColor.opacity(0.7))
								.font(.subheadline)
						}
				}
				.padding()
				.cornerRadius(10)
				.overlay(
					RoundedRectangle(
						cornerRadius: universalNewRectangleCornerRadius
					)
					.stroke(universalAccentColor, lineWidth: 1)
				)
			}
		}
		.padding(.horizontal)
	}
}
