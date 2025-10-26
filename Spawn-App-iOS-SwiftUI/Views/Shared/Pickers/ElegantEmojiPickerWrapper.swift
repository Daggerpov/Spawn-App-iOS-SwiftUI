import SwiftUI
import ElegantEmojiPicker

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
        picker.onManualDismiss = {
            DispatchQueue.main.async {
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
    
    class Coordinator: NSObject, ElegantEmojiPickerDelegate {
        var parent: ElegantEmojiPickerWrapper
        
        init(_ parent: ElegantEmojiPickerWrapper) {
            self.parent = parent
        }
        
        func emojiPicker(_ picker: ElegantEmojiPicker, didSelectEmoji emoji: Emoji?) {
            let selectedEmojiString = emoji?.emoji ?? "⭐️"
            print("DEBUG: Emoji selected: \(selectedEmojiString)")
            
            // Update selectedEmoji on main thread and dismiss ONLY the emoji picker
            DispatchQueue.main.async {
                self.parent.selectedEmoji = selectedEmojiString
                print("DEBUG: Updated parent.selectedEmoji to: \(self.parent.selectedEmoji)")
                
                // Dismiss only the emoji picker sheet, not the parent
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    print("DEBUG: Dismissing emoji picker sheet only")
                    self.parent.isPresented = false
                }
            }
        }
    }
}
