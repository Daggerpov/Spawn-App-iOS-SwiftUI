import SwiftUI

struct LocationRowView: View {
	let icon: String
	let iconColor: Color
	let title: String
	let subtitle: String?
	let distance: String?
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			HStack(spacing: 12) {
				Image(systemName: icon)
					.foregroundColor(iconColor)
					.font(.system(size: 16))
					.frame(width: 20)

				VStack(alignment: .leading, spacing: 2) {
					HStack {
						Text(title)
							.foregroundColor(universalAccentColor)
							.font(.system(size: 16, weight: .medium))

						Spacer()

						if let distance = distance {
							Text(distance)
								.foregroundColor(figmaBlack300)
								.font(.system(size: 14))
						}
					}

					if let subtitle = subtitle, !subtitle.isEmpty {
						Text(subtitle)
							.font(.system(size: 14))
							.foregroundColor(figmaBlack300)
							.multilineTextAlignment(.leading)
					}
				}

				Spacer()
			}
			.padding(.vertical, 8)
			.contentShape(Rectangle())
		}
		.buttonStyle(PlainButtonStyle())
	}
}

