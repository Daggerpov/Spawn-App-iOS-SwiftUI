import SwiftUI

// Settings Toggle Row Component (same layout as SettingsRow, with a switch instead of a disclosure)
struct SettingsToggleRow: View {
	let icon: String
	let title: String
	@Binding var isOn: Bool

	var body: some View {
		Toggle(isOn: $isOn) {
			HStack {
				Image(systemName: icon)
					.font(.system(size: 18))
					.foregroundColor(universalAccentColor)
					.frame(width: 24, height: 24)

				Text(title)
					.font(.body)
					.foregroundColor(universalAccentColor)
			}
		}
		.padding(.horizontal)
		.frame(height: 44)
	}
}
