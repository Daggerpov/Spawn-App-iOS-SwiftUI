import SwiftUI

// MARK: - Feedback Type Selector Component
struct FeedbackTypeSelector: View {
	@Binding var selectedType: FeedbackType

	var body: some View {
		HStack(spacing: 10) {
			Text("Feedback Type")
				.font(.headline)
				.foregroundColor(universalAccentColor)
				.fixedSize()

			// Custom menu label: the default menu picker label wraps long names onto two lines.
			// It takes the rest of the row, trailing-aligned, so changing the type doesn't shift the row.
			Menu {
				Picker("", selection: $selectedType) {
					ForEach(FeedbackType.allCases) { type in
						Label(type.displayName, systemImage: type.iconName)
							.tag(type)
					}
				}
			} label: {
				HStack(spacing: 6) {
					Image(systemName: selectedType.iconName)
					Text(selectedType.displayName)
						.lineLimit(1)
					Image(systemName: "chevron.up.chevron.down")
						.font(.caption)
				}
				.foregroundColor(universalAccentColor)
			}
			.frame(maxWidth: .infinity, alignment: .trailing)
		}
		.padding(.horizontal)
	}
}
