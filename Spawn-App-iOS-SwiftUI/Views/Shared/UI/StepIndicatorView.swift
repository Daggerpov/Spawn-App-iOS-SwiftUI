import SwiftUI

struct StepIndicatorView: View {
	let currentStep: Int
	let totalSteps: Int

	var body: some View {
		HStack(spacing: 8) {
			ForEach(1...totalSteps, id: \.self) { step in
				RoundedRectangle(cornerRadius: 16)
					.fill(step <= currentStep ? figmaGreen : Color(hex: "#E0DADA"))
					.frame(width: 32, height: 8)
					.overlay(
						RoundedRectangle(cornerRadius: 16)
							.stroke(step <= currentStep ? figmaGreen : Color.gray.opacity(0.2), lineWidth: 0.5)
							.shadow(color: Color.black.opacity(0.9), radius: 1.2, x: -2, y: -1.5)  // dark shadow top
							.clipShape(RoundedRectangle(cornerRadius: 16))
							.shadow(color: Color.white.opacity(0.1), radius: 1, x: 0, y: 1)  // light shadow bottom
							.clipShape(RoundedRectangle(cornerRadius: 16))
					)
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
