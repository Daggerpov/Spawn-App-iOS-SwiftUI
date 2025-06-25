import SwiftUI

struct ActivityNextStepButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    init(title: String = "Next Step", isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        VStack {
            Button(action: action) {
                HStack(alignment: .center, spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(isEnabled ? universalSecondaryColor : Color.gray)
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.6)
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