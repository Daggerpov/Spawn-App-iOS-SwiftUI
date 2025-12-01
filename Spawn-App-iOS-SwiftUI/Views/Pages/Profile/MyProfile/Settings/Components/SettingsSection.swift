import SwiftUI

// Settings Section Component
struct SettingsSection<Content: View>: View {
	let title: String
	let content: Content

	init(title: String, @ViewBuilder content: () -> Content) {
		self.title = title
		self.content = content()
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text(title)
				.font(.caption)
				.foregroundColor(.gray)
				.padding(.horizontal)

			VStack(spacing: 1) {
				content
			}
			.background(Color.secondary.opacity(0.1))
			.cornerRadius(10)
		}
	}
}
