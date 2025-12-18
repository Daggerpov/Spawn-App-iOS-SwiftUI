import SwiftUI

// MARK: - SwiftUI Sheet Presentation Helper
@MainActor
struct ElegantEmojiPickerView: View {
	@Binding var selectedEmoji: String
	@Binding var isPresented: Bool

	var body: some View {
		ElegantEmojiPickerWrapper(selectedEmoji: $selectedEmoji, isPresented: $isPresented)
	}
}
