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
					.foregroundColor(universalAccentColor)
					.padding(.horizontal, 16)
					.padding(.vertical, 14)
					.background(
						RoundedRectangle(cornerRadius: universalNewRectangleCornerRadius)
							.fill(Color.clear)
					)
					.overlay(
						RoundedRectangle(cornerRadius: universalNewRectangleCornerRadius)
							.stroke(universalAccentColor, lineWidth: 1)
					)
					.placeholder(when: name.isEmpty) {
						Text("Full Name")
							.foregroundColor(universalAccentColor.opacity(0.5))
							.font(.subheadline)
							.padding(.leading, 16)
					}
			}

			// Username field
			VStack(alignment: .leading, spacing: 6) {
				Text("Username")
					.font(.subheadline)
					.foregroundColor(.gray)

				HStack(spacing: 4) {
					Text("@")
						.foregroundColor(.gray)
						.font(.subheadline)

					TextField("username", text: $username)
						.foregroundColor(universalAccentColor)
						.font(.subheadline)
						.placeholder(when: username.isEmpty) {
							Text("username")
								.foregroundColor(universalAccentColor.opacity(0.5))
								.font(.subheadline)
						}
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 14)
				.background(
					RoundedRectangle(cornerRadius: universalNewRectangleCornerRadius)
						.fill(Color.clear)
				)
				.overlay(
					RoundedRectangle(cornerRadius: universalNewRectangleCornerRadius)
						.stroke(universalAccentColor, lineWidth: 1)
				)
			}
		}
		.padding(.horizontal)
	}
}
