import SwiftUI

// MARK: - Interest Chip View
struct InterestChipView: View {
	let interest: String
	let onRemove: () -> Void

	var body: some View {
		HStack(spacing: 8) {
			Text(interest)
				.font(.custom("Onest", size: 14).weight(.medium))
				.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))

			Button(action: onRemove) {
				Image(systemName: "xmark")
					.font(.system(size: 10, weight: .semibold))
					.foregroundColor(Color(red: 0.88, green: 0.36, blue: 0.45))
			}
		}
		.padding(12)
		.background(Color(red: 0.86, green: 0.84, blue: 0.84))
		.cornerRadius(100)
	}
}
