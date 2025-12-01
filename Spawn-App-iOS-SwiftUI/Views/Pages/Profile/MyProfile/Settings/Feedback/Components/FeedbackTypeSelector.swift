import SwiftUI

// MARK: - Feedback Type Selector Component
struct FeedbackTypeSelector: View {
	@Binding var selectedType: FeedbackType

	var body: some View {
		HStack(spacing: 10) {
			Text("Feedback Type")
				.font(.headline)
				.foregroundColor(universalAccentColor)

			Picker("", selection: $selectedType) {
				ForEach(FeedbackType.allCases) { type in
					VStack {
						Image(systemName: type.iconName)
						Text(type.displayName)
					}
					.tag(type)
				}
			}
			.tint(universalAccentColor)
			.accentColor(universalAccentColor)
		}
		.padding(.horizontal)
	}
}
