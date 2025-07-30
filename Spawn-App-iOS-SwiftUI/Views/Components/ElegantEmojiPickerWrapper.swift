import SwiftUI
import ElegantEmojiPicker

// Custom subclass to prevent auto-dismissal
class NonDismissingElegantEmojiPicker: ElegantEmojiPicker {
    var onManualDismiss: (() -> Void)?
    private var allowDismissal = false
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if allowDismissal {
            print("DEBUG: Allowing manual dismissal")
            super.dismiss(animated: flag, completion: completion)
        } else {
            print("DEBUG: Prevented automatic dismissal of emoji picker")
            completion?()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("DEBUG: NonDismissingElegantEmojiPicker loaded")
    }
    
    // Allow manual dismissal through this method
    func manualDismiss() {
        print("DEBUG: Manual dismissal triggered")
        allowDismissal = true
        onManualDismiss?()
    }
    
    // Override other potential dismissal methods
    override func viewDidDisappear(_ animated: Bool) {
        if allowDismissal {
            super.viewDidDisappear(animated)
        } else {
            print("DEBUG: Prevented viewDidDisappear")
        }
    }
}

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
            
            // Update selectedEmoji on main thread - do NOT automatically dismiss
            DispatchQueue.main.async {
                self.parent.selectedEmoji = selectedEmojiString
                print("DEBUG: Updated parent.selectedEmoji to: \(self.parent.selectedEmoji)")
                // Note: Removed automatic dismissal - let user manually close the picker
            }
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