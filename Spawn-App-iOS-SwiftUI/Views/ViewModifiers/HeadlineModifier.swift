import SwiftUI

// MARK: - Text Modifiers for Onest Font
struct HeadlineModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.font(.onestBold(size: 20))
	}
}
