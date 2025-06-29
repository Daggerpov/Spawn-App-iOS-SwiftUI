import SwiftUI

struct StepIndicatorView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? figmaSoftBlue : figmaLightGrey)
                    .frame(width: 12, height: 12)
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