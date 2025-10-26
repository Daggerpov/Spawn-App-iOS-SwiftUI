import SwiftUI

// MARK: - Message Input Component
struct MessageInputView: View {
    @Binding var message: String
    @Binding var isFocused: Bool
    @FocusState private var textFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Message")
                .font(.headline)
                .foregroundColor(universalAccentColor)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $message)
                    .foregroundColor(universalAccentColor)
                    .scrollContentBackground(.hidden)
                    .background(universalBackgroundColor)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .focused($textFieldFocused)
                    .onChange(of: textFieldFocused) { _, newValue in
                        isFocused = newValue
                    }
                    .onChange(of: isFocused) { _, newValue in
                        textFieldFocused = newValue
                    }
                    .onSubmit {
                        textFieldFocused = false
                    }
                
                if message.isEmpty && !textFieldFocused {
                    Text("Share your thoughts, report a bug, or suggest a feature...")
                        .foregroundColor(universalPlaceHolderTextColor)
                        .padding(.leading, 16)
                        .padding(.top, 16)
                        .allowsHitTesting(false)
                }
            }
            .onTapGesture {
                if !textFieldFocused {
                    textFieldFocused = true
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)
    }
}

