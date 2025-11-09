import SwiftUI

/// Wrapper around UnifiedButton for backwards compatibility
/// Now uses the unified button system (DRY refactoring)
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
		UnifiedButton.primary(title, isEnabled: isEnabled, action: action)
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
