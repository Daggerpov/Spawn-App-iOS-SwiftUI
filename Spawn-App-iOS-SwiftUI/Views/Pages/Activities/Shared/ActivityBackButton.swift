import SwiftUI

/// Wrapper around UnifiedBackButton for backwards compatibility
/// Now uses the unified button system (DRY refactoring)
struct ActivityBackButton: View {
	let action: () -> Void

	var body: some View {
		UnifiedBackButton(action: action)
	}
}

@available(iOS 17, *)
#Preview {
	VStack(alignment: .leading) {
		ActivityBackButton {
			print("Back tapped")
		}
		Spacer()
	}
	.frame(maxWidth: .infinity, maxHeight: .infinity)
	.background(universalBackgroundColor)
}
