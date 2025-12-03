import ElegantEmojiPicker
import SwiftUI

@MainActor
struct ElegantEmojiPickerWrapper: UIViewControllerRepresentable {
	@Binding var selectedEmoji: String
	@Binding var isPresented: Bool

	func makeUIViewController(context: Context) -> NonDismissingElegantEmojiPicker {
		let configuration = ElegantConfiguration(
			showSearch: true,
			showRandom: false,
			showReset: true,
			showClose: true,
			showToolbar: true,
			supportsPreview: true,
			supportsSkinTones: true,
			persistSkinTones: false,
			defaultSkinTone: nil
		)

		let picker = NonDismissingElegantEmojiPicker(delegate: context.coordinator, configuration: configuration)

		// Set up manual dismiss callback
		picker.onManualDismiss = { [weak picker] in
			_ = picker  // Capture to avoid unused warning
			Task { @MainActor in
				self.isPresented = false
			}
		}

		return picker
	}

	func updateUIViewController(_ uiViewController: NonDismissingElegantEmojiPicker, context: Context) {
		// No updates needed for this implementation
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	@MainActor
	final class Coordinator: NSObject, ElegantEmojiPickerDelegate {
		var parent: ElegantEmojiPickerWrapper

		init(_ parent: ElegantEmojiPickerWrapper) {
			self.parent = parent
		}

		nonisolated func emojiPicker(_ picker: ElegantEmojiPicker, didSelectEmoji emoji: Emoji?) {
			let selectedEmojiString = emoji?.emoji ?? "⭐️"
			print("DEBUG: Emoji selected: \(selectedEmojiString)")

			// Update selectedEmoji on main actor and dismiss the emoji picker
			Task { @MainActor [weak self] in
				guard let self = self else { return }
				self.parent.selectedEmoji = selectedEmojiString
				print("DEBUG: Updated parent.selectedEmoji to: \(self.parent.selectedEmoji)")

				// Small delay to ensure UI updates properly before dismissing
				try? await Task.sleep(for: .milliseconds(100))
				print("DEBUG: Dismissing emoji picker sheet only")
				self.parent.isPresented = false
			}
		}
	}
}
