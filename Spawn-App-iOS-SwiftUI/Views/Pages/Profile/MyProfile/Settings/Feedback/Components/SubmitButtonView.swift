import SwiftUI

// MARK: - Submit Button Component
struct SubmitButtonView: View {
	var viewModel: FeedbackViewModel
	var message: String
	var onSubmit: () -> Void

	var body: some View {
		Button(action: onSubmit) {
			HStack {
				if viewModel.isSubmitting {
					ProgressView()
						.progressViewStyle(CircularProgressViewStyle(tint: .white))
						.scaleEffect(0.9)
						.padding(.trailing, 8)
				}
				Text(viewModel.isSubmitting ? "Submitting..." : "Submit Feedback")
					.font(.headline)
					.foregroundColor(.white)
			}
			.frame(maxWidth: .infinity)
			.padding(.vertical, 16)
			.background(
				RoundedRectangle(cornerRadius: 12)
					.fill(universalAccentColor)
					.opacity(message.isEmpty || viewModel.isSubmitting ? 0.6 : 1.0)
			)
		}
		.disabled(message.isEmpty || viewModel.isSubmitting)
		.padding(.horizontal)
		.animation(.easeInOut(duration: 0.2), value: viewModel.isSubmitting)
	}
}
