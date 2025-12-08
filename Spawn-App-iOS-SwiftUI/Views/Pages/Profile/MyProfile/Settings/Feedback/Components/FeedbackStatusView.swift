import SwiftUI

// MARK: - Feedback Status Component
struct FeedbackStatusView: View {
	var viewModel: FeedbackViewModel
	var onSuccess: () -> Void
	@Environment(\.colorScheme) private var colorScheme

	var body: some View {
		VStack(spacing: 8) {
			if let successMessage = viewModel.successMessage {
				HStack {
					Image(systemName: "checkmark.circle.fill")
						.font(.system(size: 16))
					Text(successMessage)
						.font(.body)
				}
				.foregroundColor(successColor)
				.padding(.horizontal, 16)
				.padding(.vertical, 12)
				.background(
					RoundedRectangle(cornerRadius: 8)
						.fill(successColor.opacity(0.1))
						.overlay(
							RoundedRectangle(cornerRadius: 8)
								.stroke(successColor.opacity(0.3), lineWidth: 1)
						)
				)
				.task {
					// Dismiss after showing success message
					try? await Task.sleep(for: .seconds(1.5))
					onSuccess()
				}
			}

			if let errorMessage = viewModel.errorMessage {
				HStack {
					Image(systemName: "exclamationmark.circle.fill")
						.font(.system(size: 16))
					Text(errorMessage)
						.font(.body)
				}
				.foregroundColor(errorColor)
				.padding(.horizontal, 16)
				.padding(.vertical, 12)
				.background(
					RoundedRectangle(cornerRadius: 8)
						.fill(errorColor.opacity(0.1))
						.overlay(
							RoundedRectangle(cornerRadius: 8)
								.stroke(errorColor.opacity(0.3), lineWidth: 1)
						)
				)
			}
		}
		.padding(.horizontal)
	}

	private var successColor: Color {
		colorScheme == .dark ? Color.green.opacity(0.8) : Color.green
	}

	private var errorColor: Color {
		colorScheme == .dark ? Color.red.opacity(0.8) : Color.red
	}
}
