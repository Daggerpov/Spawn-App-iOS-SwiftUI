import SwiftUI

struct StepIndicatorView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? figmaGreen : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
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