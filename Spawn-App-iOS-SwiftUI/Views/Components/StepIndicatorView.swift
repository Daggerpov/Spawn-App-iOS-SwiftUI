import SwiftUI

struct StepIndicatorView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 3)
                    .fill(step <= currentStep ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: step <= currentStep ? 24 : 16, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StepIndicatorView(currentStep: 1, totalSteps: 3)
        StepIndicatorView(currentStep: 2, totalSteps: 3)
        StepIndicatorView(currentStep: 3, totalSteps: 3)
    }
    .padding()
} 