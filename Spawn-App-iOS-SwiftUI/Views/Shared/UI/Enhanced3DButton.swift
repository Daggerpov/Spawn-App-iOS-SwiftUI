import SwiftUI

/// Wrapper around UnifiedButton for backwards compatibility
/// Now uses the unified button system (DRY refactoring)
struct Enhanced3DButton: View {
	let title: String
	let backgroundColor: Color
	let foregroundColor: Color
	let borderColor: Color?
	let isEnabled: Bool
	let action: () -> Void

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
		UnifiedButton(
			title,
			variant: .custom(
				backgroundColor: backgroundColor,
				foregroundColor: foregroundColor,
				borderColor: borderColor
			),
			isEnabled: isEnabled,
			action: action
		)
	}
}

@available(iOS 17, *)
#Preview {
	VStack(spacing: 20) {
		Enhanced3DButton(title: "Next Step", isEnabled: true) {
			print("Next step tapped")
		}

		Enhanced3DButton(
			title: "Cancel", backgroundColor: Color.clear, foregroundColor: Color(red: 0.15, green: 0.14, blue: 0.14),
			borderColor: Color(red: 0.15, green: 0.14, blue: 0.14), isEnabled: true
		) {
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
