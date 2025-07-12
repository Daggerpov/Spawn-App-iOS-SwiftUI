import SwiftUI
import ElegantEmojiPicker

struct ElegantEmojiPickerWrapper: UIViewControllerRepresentable {
    @Binding var selectedEmoji: String
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> ElegantEmojiPicker {
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
        
        let picker = ElegantEmojiPicker(delegate: context.coordinator, configuration: configuration)
        return picker
    }
    
    func updateUIViewController(_ uiViewController: ElegantEmojiPicker, context: Context) {
        // No updates needed for this implementation
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ElegantEmojiPickerDelegate {
        var parent: ElegantEmojiPickerWrapper
        
        init(_ parent: ElegantEmojiPickerWrapper) {
            self.parent = parent
        }
        
        func emojiPicker(_ picker: ElegantEmojiPicker, didSelectEmoji emoji: Emoji?) {
            parent.selectedEmoji = emoji?.emoji ?? "⭐️" // Default emoji if reset is selected
            parent.isPresented = false
        }
    }
}

// MARK: - SwiftUI Sheet Presentation Helper
struct ElegantEmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Binding var isPresented: Bool
    
    var body: some View {
        ElegantEmojiPickerWrapper(selectedEmoji: $selectedEmoji, isPresented: $isPresented)
    }
} 