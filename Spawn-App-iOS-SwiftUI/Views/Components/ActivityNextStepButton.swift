import SwiftUI

struct ActivityNextStepButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    // Animation states
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
    init(title: String = "Next Step", isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        VStack {
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
                        .foregroundColor(.white)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(isEnabled ? figmaSoftBlue : figmaLightGrey)
                .cornerRadius(16)
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
            .opacity(isEnabled ? 1.0 : 0.7)
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
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
    }
}

@available(iOS 17, *)
#Preview {
    VStack(spacing: 20) {
        ActivityNextStepButton(isEnabled: true) {
            print("Next step tapped")
        }
        
        ActivityNextStepButton(title: "Create Activity", isEnabled: false) {
            print("Create activity tapped")
        }
        
        ActivityNextStepButton(title: "Confirm Location", isEnabled: true) {
            print("Confirm location tapped")
        }
    }
    .padding()
    .background(universalBackgroundColor)
} 
