import SwiftUI

struct Enhanced3DButton: View {
    let title: String
    let backgroundColor: Color
    let foregroundColor: Color
    let borderColor: Color?
    let isEnabled: Bool
    let action: () -> Void
    
    // Animation states
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
    init(
        title: String,
        backgroundColor: Color = Color(red: 0.42, green: 0.51, blue: 0.98),
        foregroundColor: Color = .white,
        borderColor: Color? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.borderColor = borderColor
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
            // Execute action with slight delay for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
            }
        }) {
            HStack(alignment: .center, spacing: 8) {
                Text(title)
                    .font(.onestSemiBold(size: 16))
                    .foregroundColor(foregroundColor)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(isEnabled ? backgroundColor : Color.gray.opacity(0.3))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor ?? Color.clear, lineWidth: borderColor != nil ? 1 : 0)
            )
            .scaleEffect(scale)
            .shadow(
                color: isEnabled ? Color.black.opacity(0.15) : Color.clear,
                radius: isPressed ? 2 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.8)
        .animation(.easeInOut(duration: 0.15), value: scale)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isEnabled && !isPressed {
                        isPressed = true
                        scale = 0.95
                        
                        // Additional haptic feedback for press down
                        let selectionGenerator = UISelectionFeedbackGenerator()
                        selectionGenerator.selectionChanged()
                    }
                }
                .onEnded { _ in
                    if isEnabled {
                        isPressed = false
                        scale = 1.0
                    }
                }
        )
    }
}

@available(iOS 17, *)
#Preview {
    VStack(spacing: 20) {
        Enhanced3DButton(title: "Next Step", isEnabled: true) {
            print("Next step tapped")
        }
        
        Enhanced3DButton(title: "Cancel", backgroundColor: Color.clear, foregroundColor: Color(red: 0.15, green: 0.14, blue: 0.14), borderColor: Color(red: 0.15, green: 0.14, blue: 0.14), isEnabled: true) {
            print("Cancel tapped")
        }
        
        Enhanced3DButton(title: "Share", backgroundColor: Color.blue, isEnabled: true) {
            print("Share tapped")
        }
        
        Enhanced3DButton(title: "Disabled", isEnabled: false) {
            print("Disabled tapped")
        }
    }
    .padding()
    .background(Color(red: 0.12, green: 0.12, blue: 0.12))
} 